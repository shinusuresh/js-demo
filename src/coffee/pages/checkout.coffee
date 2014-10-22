##############
## CHECKOUT ##
##############

app.controller 'checkoutController', ['$scope', '$routeParams', '$rootScope', '$location', 'Moltin', 'Page', ($scope, $routeParams, $rootScope, $location, Moltin, Page) ->

	# Page setup
	Page.titleSet 'Checkout'
	$scope.customer = 919
	$scope.data     = {bill: {}, ship: {}, ship_bill: 0, notes: '', shipping: '', gateway: ''}
	Page.loader.set 2

	# Create order
	$scope.createOrder = (data) ->

		# Format
		$scope.data.bill.customer = $scope.customer
		$scope.data.ship.customer = $scope.customer

		console.log $scope.data

		# Create order
		Moltin.Cart.Complete
			customer: $scope.customer
			gateway: $scope.data.gateway
			shipping: $scope.data.shipping
			bill_to: $scope.data.bill
			ship_to: if $scope.data.ship_bill then 'bill_to' else $scope.data.ship
		, (response) ->

			$rootScope.order = response
			
			$rootScope.$apply () ->
				$location.path '/checkout/payment'

			return null

	# Get checkout options
	Moltin.Cart.Checkout (options) ->

		# Assign data
		$scope.options = options
		Page.loader.update()
		$scope.$apply()

	# Get address fields
	Moltin.Address.Fields $scope.customer, 0, (fields) ->

		# Assign data
		$scope.fields = fields
		Page.loader.update()
		$scope.$apply()

	return null
]
