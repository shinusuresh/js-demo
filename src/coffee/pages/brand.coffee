###########
## BRAND ##
###########

app.controller 'brandController', ['$scope', '$routeParams', 'Moltin', 'Page', ($scope, $routeParams, Moltin, Page) ->

	# Variables
	$scope.pageCurrent = 0
	$scope.pagination  = {total: 0, limit: 12, offset: 0}
	Page.loader.set 2

	# Page change
	$scope.$watch 'pageCurrent', (n, o) ->

		if $scope.brand
			Page.loader.set 1
			$scope.pageChange n

	# Pagination change
	$scope.pageChange = (page) ->

		# Change offset
		$scope.pagination.offset = if page > 1 then ( page - 1 ) * $scope.pagination.limit else 0

		# Get products
		Moltin.Product.List {brand: $scope.brand.id, status: 1, limit: $scope.pagination.limit, offset: $scope.pagination.offset}, (products, pagination) ->

			# Check products
			if products.length <= 0
				Page.notice.set 'info', 'No products found in "'+$scope.brand.title+'"'
			
			# Format products
			else
				for k,v of products
					products[k] = Page.format.product v

			# Assign data
			$scope.products   = products
			$scope.pagination = pagination
			Page.loader.update()
			$scope.$apply()

	# Get the category
	Moltin.Brand.Find {slug: $routeParams.slug, status: 1}, (brand) ->

		# Page options
		Page.titleSet brand.title

		# Assign data
		$scope.brand = brand
		Page.loader.update()
		$scope.$apply()
		$scope.pageChange 1

	return null
]
