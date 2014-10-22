##########
## PAGE ##
##########

app.controller 'pageController', ['$scope', '$routeParams', '$location', 'Page', ($scope, $routeParams, $location, Page) ->

	# Page change
	$scope.$watchCollection 'pages', () ->

		# Get page contents
		if typeof $scope.pages[$routeParams.page] != 'undefined'

			# Page setup
			page = $scope.pages[$routeParams.page]
			Page.titleSet page.title

			# Assign data
			$scope.content = page

			if ! $scope.$$phase
				$scope.$apply()

		else if Object.keys($scope.pages).length > 0
			$location.path '/error'

	return null
]
