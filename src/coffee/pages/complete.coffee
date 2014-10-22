####################
## ORDER COMPLETE ##
####################

app.controller 'completeController', ['$scope', '$routeParams', '$location', 'Moltin', 'Page', ($scope, $routeParams, $location, Moltin, Page) ->

	# Check order
	if typeof $scope.payment == 'undefined'
		$location.path '/payment'

	# Redirect
	# if $scope.payment.redirect != false
	# 	window.location $scope.payment.redirect

	# Page setup
	Page.titleSet $scope.payment.message
	Page.notice.set 'success', $scope.payment.message

	return null
]