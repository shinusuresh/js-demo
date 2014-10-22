##############
## HOMEPAGE ##
##############

app.controller 'homeController', ['$scope', '$route', 'Moltin', 'Page', ($scope, $route, Moltin, Page) ->

	# Page options
	Page.titleSet 'Home'
	Page.loader.set 3

	# Get featured products
	Moltin.Product.Search {featured: 1, status: 1, limit: 9}, (products) ->

		# Format products
		for k,v of products
			products[k] = Page.format.product v

		# Assign data
		$scope.products = products
		Page.loader.update()
		$scope.$apply()

	# Get collections
	Moltin.Collection.List {status: 1, limit: 10}, (collections) ->

		# Assign data
		$scope.collections = collections
		Page.loader.update()
		$scope.$apply()

	# Get available currencies
	Moltin.Currency.List {enabled: '1'}, (currencies) ->

		# Assign data
		$scope.currencies = currencies
		Page.loader.update()
		$scope.$apply()

	return null
]
