angular.module("deploydApp", ["ngResource", "ui.bootstrap", "checklist-model"])
  .controller("resourceCtrl", function ($scope, $http, $resource, $location) {

    $scope.baseUrl = "http://" + $location.host() + ":" + $location.port() + "/"
    $scope.resourceUrl = $scope.baseUrl + $scope.routeKey + '/';
    $scope.displayMode = "list";
    $scope.currentResource = null;
    $scope.error = null;
    $scope.checkedResources = [];
    $scope.checkedAll = false;
    $scope.checkedSeveral = false;

    $scope.checkAll = function() {
      angular.copy($scope.resources.map(function(item) { return item.id; }), $scope.checkedResources);
    };

    $scope.uncheckAll = function() {
      angular.copy([], $scope.checkedResources);
    };

    $scope.changeCheck = function() {
      if ($scope.checkedAll) {
        $scope.uncheckAll();
        $scope.checkedAll = false;
      } else {
        $scope.checkAll();
        $scope.checkedAll = true;
      };
    };

    $scope.$watch('checkedResources.length', function() {
      if ($scope.checkedResources.length > 1) {
        $scope.checkedSeveral = true;
      } else {
        $scope.checkedSeveral = false;
      };
    });

    $scope.selfResource = $resource($scope.resourceUrl + ":id", { id: "@id" },
      { create: { method: "POST" }, save: { method: "PUT" }, query: { isArray: true } }
    );

    $scope.listResources = function () {
      $scope.resources = $scope.selfResource.query();
    }

    $scope.deleteResource = function (resource) {
      resource.$delete().then(function() {
        $scope.resources.splice($scope.resources.indexOf(resource), 1);
      });
      $scope.displayMode = 'list';
    }

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
    }

    $scope.updateResource = function (resource) {
      resource.$save().then(
        function (modifiedResource) {
          $scope.clearError();
          $scope.displayMode = "list";
        }, function (error) {
          $scope.error = error.data;
        }
      );
    }

    $scope.editOrCreateResource = function (resource) {
      $scope.currentResource = resource ? resource : {};
      $scope.displayMode  = 'edit';
    }

    $scope.saveEdit = function (resource) {
      if (angular.isDefined(resource.id)) {
        $scope.updateResource(resource);
      } else {
        $scope.createResource(resource);
      }
    }

    $scope.cancelEdit = function () {
      if ($scope.currentResource && $scope.currentResource.$get) {
        $scope.currentResource.$get;
      } else {
        $scope.currentResource = {};
      }
      $scope.clearError();
      $scope.displayMode = 'list';
    }

    $scope.clearError = function () {
      $scope.error = null;
    }

    $scope.listResources();

  });
