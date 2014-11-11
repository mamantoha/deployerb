angular.module("deploydApp", ["ngResource", "ui.bootstrap"])
  .constant("baseUrl", "http://localhost:9292/")
  .controller("resourceCtrl", function ($scope, $http, $resource, baseUrl) {

    $scope.resourceUrl = baseUrl + $scope.routeKey + '/';
    $scope.displayMode = "list";
    $scope.currentResource = null;

    $scope.selfResource = $resource($scope.resourceUrl + ":id", { id: "@id" },
      { create: { method: "POST" }, save: { method: "PUT" }, query: { isArray: true } }
    );

    $scope.listResources = function () {
      $scope.resources = $scope.selfResource.query();
      console.log($scope.resources);
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
          $scope.displayMode = 'list';
        },
        function (error) {
          console.log(error.data);
        }
      );
    }

    $scope.updateResource = function (resource) {
      resource.$save();
      $scope.displayMode = "list";
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

    $scope.cancelEdit = function() {
      if ($scope.currentResource && $scope.currentResource.$get) {
        $scope.currentResource.$get;
      }
      $scope.currentResource = {};
      $scope.displayMode = 'list';
    }

    $scope.listResources();

  });
