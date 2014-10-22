############
## SEARCH ##
############

app.controller 'searchController', ['$scope', '$routeParams', 'Moltin', 'Page', ($scope, $routeParams, Moltin, Page) ->

	# Check for search term
	if typeof $routeParams.term != 'undefined'

		# Page setup
		Page.titleSet 'Search "'+$routeParams.term+'"'
		$scope.term   = $routeParams.term
		$scope.search = $routeParams.term
		
		# Search products
		Moltin.Product.Search {title: $scope.search, status: 1, limit: 9}, (products) ->

			# Format products
			for k,v of products
				products[k] = Page.format.product v

			# Assign data
			$scope.products = products
			$scope.$apply()

	else

		# Page setup
		Page.titleSet 'Search'

	return null
]
