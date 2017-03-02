import tabs from 'angular-ui-bootstrap/src/tabs'
import pagination from 'angular-ui-bootstrap/src/pagination'
import ChecklistDirective from 'checklist-model'

angular.module("deploydApp", ["ngResource", ChecklistDirective, tabs, pagination])
  .controller("ResourceController", function ($scope, $http, $resource, $location, $log) {

    $scope.apiSubdomain = "api";
    $scope.baseUrl = "http://" + $scope.apiSubdomain + "." + $location.host() + ":" + $location.port() + "/";
    $scope.resourceUrl = $scope.baseUrl + $scope.routeKey + '/';
    $scope.displayMode = "list";
    $scope.currentResource = null;
    $scope.error = null;
    $scope.checkedResources = [];
    $scope.checkedAll = false;
    $scope.checkedSeveral = false;

    $scope.pagination = {
      currentPage: 1,
      resourcesPerPage: 2,
      resources: []
    };
    $scope.totalResources = 1;

    $scope.pageChanged = function() {
      var begin = (($scope.pagination.currentPage - 1) * $scope.pagination.resourcesPerPage);
      var end = begin + $scope.pagination.resourcesPerPage;

      $scope.pagination.resources = $scope.resources.slice(begin, end);
      $log.log('Page changed to: ' + $scope.pagination.currentPage);
    };

    $scope.$watch('resources.length', function() {
      $scope.totalResources = $scope.resources.length;
      $scope.pageChanged();
    });

    $scope.checkAll = function() {
      angular.copy($scope.resources.map(function(item) { return item._id; }), $scope.checkedResources);
      $scope.checkedAll = true;
    };

    $scope.uncheckAll = function() {
      angular.copy([], $scope.checkedResources);
      $scope.checkedAll = false;
    };

    $scope.changeCheck = function() {
      if ($scope.checkedAll) {
        $scope.uncheckAll();
        $scope.checkedAll = false;
      } else {
        $scope.checkAll();
        $scope.checkedAll = true;
      }
    };

    $scope.$watch('checkedResources.length', function() {
      if ($scope.checkedResources.length > 1) {
        $scope.checkedSeveral = true;
      } else {
        $scope.checkedSeveral = false;
      }
    });

    $scope.selfResource = $resource($scope.resourceUrl + ":id", { id: "@_id" },
      { create: { method: "POST" }, save: { method: "PUT" }, query: { isArray: true } }
    );

    $scope.listResources = function () {
      $scope.resources = $scope.selfResource.query();
      $scope.resources.$promise.then(function (result) {
        $scope.resources = result;
      });
    };

    $scope.deleteResource = function (resource) {
      resource.$delete().then(function() {
        $scope.resources.splice($scope.resources.indexOf(resource), 1);
      });
      $scope.displayMode = 'list';
    };

    $scope.createResource = function (resource) {
      new $scope.selfResource(resource).$create().then(
        function (newResource) {
          $scope.resources.push(newResource);
          $scope.clearError();
          $scope.displayMode = 'list';
        },
        function (error) {
          $scope.error = error.data;
        }
      );
    };

    $scope.updateResource = function (resource) {
      resource.$save().then(
        function (modifiedResource) {
          $scope.clearError();
          $scope.displayMode = "list";
        }, function (error) {
          $scope.error = error.data;
        }
      );
    };

    $scope.editOrCreateResource = function (resource) {
      $scope.currentResource = resource ? resource : {};
      $scope.displayMode  = 'edit';
    };

    $scope.saveEdit = function (resource) {
      if (angular.isDefined(resource._id)) {
        $scope.updateResource(resource);
      } else {
        $scope.createResource(resource);
      }
    };

    $scope.cancelEdit = function () {
      $scope.currentResource = {};
      $scope.clearError();
      $scope.displayMode = 'list';
    };

    $scope.clearError = function () {
      $scope.error = null;
    };

    $scope.inputType = function (inputType) {
      switch(inputType) {
        case 'String':
          return 'text';
        case 'Integer':
          return 'number';
        default:
          return 'text';
      }
    };

    $scope.listResources();
  });
