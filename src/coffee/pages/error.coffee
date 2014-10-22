###########
## ERROR ##
###########

app.controller 'errorController', ['$scope', '$routeParams', '$location', 'Page', ($scope, $routeParams, $location, Page) ->

	# Not found
	if $scope.error == '404'

		$scope.message = 
			type:  '404'
			title: 'Page not found'
			msg:   'We\'re sorry, the page you are looking for might have been removed, had its name changed or is temporarily unavailable.'

	else
		$location.path '/'

	return null
]
