####################
## DEMO STORE APP ##
####################

# Start the app
app = angular.module 'store', ['ngRoute', 'ngSanitize', 'ui.bootstrap', 'templates-main', 'ImageZoom']

# Config
app.value 'siteName', 'Molkea'
app.value 'publicKey', 'umRG34nxZVGIuCSPfYf8biBSvtABgTR8GMUtflyE'

# Set routes & page definitions
app.config ['$routeProvider', '$locationProvider', ($routeProvider, $locationProvider) ->

	$locationProvider.html5Mode(true)
	
	$routeProvider

	.when '/',
		templateUrl : '/pages/home.html'
		controller  : 'homeController'

	.when '/category/:slug',
		templateUrl : '/pages/category.html'
		controller  : 'categoryController'

	.when '/collections',
		templateUrl : '/pages/collections.html'
		controller  : 'collectionsController'

	.when '/collection/:slug',
		templateUrl : '/pages/collection.html'
		controller  : 'collectionController'

	.when '/brand/:slug',
		templateUrl : '/pages/brand.html'
		controller  : 'brandController'

	.when '/product/:slug',
		templateUrl : '/pages/product.html'
		controller  : 'productController'

	.when '/search/:term?',
		templateUrl : '/pages/search.html'
		controller  : 'searchController'

	.when '/cart',
		templateUrl : '/pages/cart.html'
		controller  : 'cartController'

	.when '/checkout/payment',
		templateUrl : '/pages/payment.html'
		controller  : 'paymentController'

	.when '/checkout/:status',
		templateUrl : '/pages/complete.html'
		controller  : 'completeController'

	.when '/checkout',
		templateUrl : '/pages/checkout.html'
		controller  : 'checkoutController'

	.when '/error',
		templateUrl : '/pages/error.html'
		controller  : 'errorController'

	.when '/:page*',
		templateUrl : '/pages/page.html',
		controller  : 'pageController'

	return null
]

#############
## FACTORY ##
#############

# Moltin class injection and authentication
app.factory 'Moltin', ['$rootScope', '$location', 'publicKey', ($rootScope, $location, publicKey) ->

	# Start SDK
	moltin = new Moltin
		publicId: publicKey
		notice: (type, msg, code) ->
			if code == '404'
				$rootScope.error = code
				$location.path '/error'
			
			else
				$rootScope.notices = []
				type = if type == 'error' then 'danger' else type
				if typeof msg == 'string' 
					$rootScope.notices.push {type: type, msg: msg}
				else
					for e,p of msg
						data = ''
						if typeof p == 'string'
							data = p
						else
							data += v+'<br />' for k,v of p

						$rootScope.notices.push {type: type, msg: data}

			$rootScope.$apply()

	# Authenticate
	return moltin.Authenticate()
]

# Page actions
app.factory 'Page', ['$rootScope', '$location', 'Moltin', 'siteName', ($rootScope, $location, Moltin, siteName) ->

	# Variables
	$rootScope.siteName = siteName
	$rootScope.title    = 'Home'
	$rootScope.notices  = []
	$rootScope.term     = ''
	$rootScope.loader   = {todo: 0, done: 0}
	$rootScope.cache    = {product: {}, category: {}}

	# Clear notices on page change
	$rootScope.$on '$routeChangeStart', (next, current) ->
		$rootScope.notices = []

	# First item
	first = (obj) ->
		return obj[Object.keys(obj)[0]]

	return {

		titleSet: (newTitle) ->
			$rootScope.title = newTitle

		currencySet: (currency) ->
			Moltin.Currency.Set currency, (data) ->
				window.location.reload()

		search: (term) ->
			$location.path '/search/'+term

		image:

			resize: (image, h, w, type = 'fit') ->

				return 'http://'+image.segments.domain+'/w'+w+'/h'+h+'/'+( if type != '' then type+'/' else '' )+image.segments.suffix

		notice:

			set: (type, msg) ->
				$rootScope.notices.push {type: type, msg: msg}

			dismiss: (key) ->
				$rootScope.notices.splice key, 1

		loader:

			set: (num) ->
				$rootScope.loader = {todo: num, done: 0}

				setTimeout () ->
					$rootScope.loader = {todo: 0, done: 0}
				, 3000

			update: () ->
				$rootScope.loader.done++

		format:

			category: (category) ->
				category.image = if Object.keys(category.images).length > 0 then first category.images else {url: {http: '/img/no-img.jpg', https: '/img/no-img.jpg'}}

				$rootScope.cache.category[category.slug] = category

				return category

			collection: (collection) ->
				collection.image = if Object.keys(collection.images).length > 0 then first collection.images else {url: {http: '/img/no-img.jpg', https: '/img/no-img.jpg'}}
				return collection

			product: (product) ->
				product.category = first product.category.data
				product.image    = if Object.keys(product.images).length > 0 then first product.images else {url: {http: '/img/no-img.jpg', https: '/img/no-img.jpg'}}
				
				$rootScope.cache.product[product.slug] = product

				return product

	}
]

###############
## DIRECTIVE ##
###############

# Homepage slider
app.directive 'slideshow', () ->

	return (scope, el, attrs) ->

		$(el).camera	
			imagePath: '/img/slideshow/'

# Card formatting
app.directive 'cardFormat', () ->

	return (scope, el, attrs) ->

		el.bind 'keyup focus blur', () ->
			$(this).val (i, v) ->
				v = v.replace(/[^\d]/g, '').match(/.{1,4}/g)
				return ( if v then v.join ' ' else '' ).substr 0, 19

# Cart insertion
app.directive 'cartInsert', ['$rootScope', 'Moltin', 'Page', ($rootScope, Moltin, Page) ->

	return (scope, el, attrs) ->

		el.bind 'click', () ->

			# Variables
			id  = attrs.ngId # Product ID
			qty = 1          # Quantity to insert
			mod = {}         # Modifiers
			ex  = false      # Exit?

			# Quantity
			if typeof attrs.ngQty != 'undefined'

				if isNaN attrs.ngQty
					qty = if $(attrs.ngQty).val() > 0 then $(attrs.ngQty).val() else 1
				else
					qty = attrs.ngQty

			# Modifiers
			if typeof attrs.ngMod != 'undefined'

				# Clear notices
				$rootScope.notices = []

				# Loop modifier selects
				$(attrs.ngMod+' select').each () ->

					# Check values
					if $(this).val() <= 0
						Page.notice.set 'warning', 'Please select a '+$(this).attr('title')+' option before adding to cart'
						ex = true
						return null

					# Add to data
					mod[$(this).attr('ng-mod')] = $(this).val()

			# Check for errors
			if ex
				return null

			# Add to cart
			Moltin.Cart.Insert id, qty, mod, (response) ->

				# Get updated contents
				Moltin.Cart.Contents (cart) ->

					# Format products
					for k,v of cart.contents
						cart.contents[k] = Page.format.product v

					# Animate
					$("html, body").animate({ scrollTop: 0 }, 150);
					$('.navbar-right > .cart').addClass 'added'
					setTimeout () ->
						$('.navbar-right > .cart').removeClass 'added'
					, 1000

					# Apply data
					$rootScope.cart = cart
					$rootScope.$apply()
]

# Cart update and removal
app.directive 'cartQty', ['$rootScope', 'Moltin', 'Page', ($rootScope, Moltin, Page) ->

	return (scope, el, attrs) ->

		el.bind 'click', () ->

			# Variables
			id  = attrs.ngId # Product ID
			qty = 1          # Quantity to update

			# Quantity
			if typeof attrs.ngQty != 'undefined'

				if isNaN attrs.ngQty
					qty = if $(attrs.ngQty).val() > 0 then $(attrs.ngQty).val() else 1
				else
					qty = attrs.ngQty

			# Add to cart
			Moltin.Cart.Update id, {quantity: qty}, (response) ->

				# Get updated contents
				Moltin.Cart.Contents (cart) ->

					# Format products
					for k,v of cart.contents
						cart.contents[k] = Page.format.product v

					# Apply data
					$rootScope.cart = cart
					$rootScope.$apply()
]

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

##########
## CART ##
##########

app.controller 'cartController', ['$scope', 'Moltin', 'Page', ($scope, Moltin, Page) ->

	# Page setup
	Page.titleSet 'Shopping Cart'

	return null
]

##############
## CATEGORY ##
##############

app.controller 'categoryController', ['$scope', '$routeParams', 'Moltin', 'Page', ($scope, $routeParams, Moltin, Page) ->

	# Variables
	$scope.pageCurrent = 0
	$scope.pagination  = {total: 0, limit: 12, offset: 0}
	Page.loader.set 2

	# Page change
	$scope.$watch 'pageCurrent', (n, o) ->

		if $scope.category
			Page.loader.set 1
			$scope.pageChange n

	# Pagination change
	$scope.pageChange = (page) ->

		# Change offset
		$scope.pagination.offset = if page > 1 then ( page - 1 ) * $scope.pagination.limit else 0

		# Get products
		Moltin.Product.List {category: $scope.category.id, status: 1, limit: $scope.pagination.limit, offset: $scope.pagination.offset}, (products, pagination) ->

			# Check products
			if products.length <= 0
				Page.notice.set 'info', 'No products found in "'+$scope.category.title+'"'
			
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
	Moltin.Category.Find {slug: $routeParams.slug, status: 1}, (category) ->

		# Page options
		Page.titleSet category.title

		# Assign data
		$scope.category = category
		Page.loader.update()
		$scope.$apply()
		$scope.pageChange 1

	return null
]

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

################
## COLLECTION ##
################

app.controller 'collectionController', ['$scope', '$routeParams', 'Moltin', 'Page', ($scope, $routeParams, Moltin, Page) ->

	# Variables
	$scope.pageCurrent = 0
	$scope.pagination  = {total: 0, limit: 12, offset: 0}
	Page.loader.set 2

	# Page change
	$scope.$watch 'pageCurrent', (n, o) ->

		if $scope.collection
			Page.loader.set 1
			$scope.pageChange n

	# Pagination change
	$scope.pageChange = (page) ->

		# Change offset
		$scope.pagination.offset = if page > 1 then ( page - 1 ) * $scope.pagination.limit else 0

		# Get products
		Moltin.Product.List {collection: $scope.collection.id, status: 1, limit: $scope.pagination.limit, offset: $scope.pagination.offset}, (products, pagination) ->

			# Check products
			if products.length <= 0
				Page.notice.set 'info', 'No products found in "'+$scope.collection.title+'"'
			
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
	Moltin.Collection.Find {slug: $routeParams.slug, status: 1}, (collection) ->

		# Page options
		Page.titleSet collection.title

		# Assign data
		$scope.collection = Page.format.collection collection
		Page.loader.update()
		$scope.$apply()
		$scope.pageChange 1

	return null
]

#################
## COLLECTIONS ##
#################

app.controller 'collectionsController', ['$scope', 'Moltin', 'Page', ($scope, Moltin, Page) ->

	# Page options
	Page.titleSet 'Collections'
	Page.loader.set 1

	# Get the product
	Moltin.Collection.List {status: 1, limit: 9}, (collections, pagination) ->

		# Format collections
		for k,v of collections
			collections[k] = Page.format.collection v

		# Assign data
		$scope.collections = collections
		Page.loader.update()
		$scope.$apply()

	return null
]

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

#############
## PAYMENT ##
#############

app.controller 'paymentController', ['$scope', '$routeParams', '$rootScope', '$location', 'Moltin', 'Page', ($scope, $routeParams, $rootScope, $location, Moltin, Page) ->

	# Check order
	if typeof $scope.order == 'undefined' or $scope.order.id < 0
		$location.path '/checkout'

	console.log $scope.order

	# Page setup
	Page.titleSet 'Payment'
	$scope.data = {number: '4242 4242 4242 4242', expiry_month: '05', expiry_year: '2015', start_month: '04', start_year: '2014', cvv: '123'}

	# Take payment
	$scope.payment = (data) ->

		Moltin.Checkout.Payment 'purchase', $scope.order.id, {data: $scope.data}, (response) ->

			delete $rootScope.order

			$rootScope.payment = response
			$rootScope.$apply () ->
				$location.path '/checkout/complete'

	return null
]

#############
## PRODUCT ##
#############

app.controller 'productController', ['$rootScope', '$scope', '$routeParams', 'Moltin', 'Page', ($rootScope, $scope, $routeParams, Moltin, Page) ->

	# Variables
	$scope.mods = {}

	# Image zoom
	$scope.switchImage = (src) ->
		$scope.imageSrc = src

	# Display product
	$scope.display = (product) ->

		console.log product

		# Page options
		Page.titleSet product.title

		# Assign data
		if typeof product.image == 'undefined'
			$scope.product = Page.format.product product
			Page.loader.update()
		else
			$scope.product = product

		if ! $scope.$$phase
			$scope.$apply()

		# Assign modifiers
		if Object.keys(product.modifiers).length > 0
			$scope.modifiers = product.modifiers
			for k,v of product.modifiers
				$scope.mods[k] = 0

		# Watch modifiers
		$scope.$watch 'mods', (n, o) ->

			# Check not empty
			if Object.keys(n).length < 1 or JSON.stringify(n) == JSON.stringify(o)
				return false
			
			# Variables
			set    = true
			params = {status: 1, modifier: {}}

			# Check all are set
			for k, v of n
				if v == '0' or v == 0
					set = false
				else
					params.modifier[k] = v

			# Check set
			if ! set
				delete params.modifier
				params.slug = $routeParams.slug

			# Check cache
			if typeof params.modifier == 'undefined' and $scope.cache.product[$routeParams.slug] != 'undefined'
				$scope.product = $scope.cache.product[$routeParams.slug]
				if ! $scope.$$phase
					$scope.$apply()
			else
				Moltin.Product.Find params, (product) ->
					$scope.product = Page.format.product product
					$scope.$apply()

		, true

		# "Related" products
		Moltin.Product.Search {category: $scope.product.category.id, status: 1, limit: 5}, (items) ->

			products = []

			# Format products
			for k,v of items
				if ( v.id != $scope.product.id and products.length < 4 )
					products.push Page.format.product v

			# Assign data
			$scope.products = products
			if ! $scope.$$phase
				$scope.$apply()

	# Get the product
	if Object.keys($scope.cache.product).length > 0 and typeof $scope.cache.product[$routeParams.slug] != 'undefined'
		$scope.display $scope.cache.product[$routeParams.slug]
	else
		Page.loader.set 1
		Moltin.Product.Find {slug: $routeParams.slug, status: 1}, $scope.display

	return null
]

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

###############
## RUN STORE ##
###############

app.run ['$rootScope', 'Moltin', 'Page', ($rootScope, Moltin, Page) ->

	# Variables
	$rootScope.currency = if Moltin.options.currency != false then Moltin.options.currency else 'GBP'
	$rootScope.pages    = {}
	$rootScope.Page     = Page

	# Set base loader
	Page.loader.set 3

	# Make categories global
	Moltin.Category.Tree {status: 1}, (categories) ->

		# Assign data
		$rootScope.categories = categories
		Page.loader.update()
		$rootScope.$apply()

	# Make cart global
	Moltin.Cart.Contents (cart) ->

		# Format products
		for k,v of cart.contents
			cart.contents[k] = Page.format.product v

		# Assign data
		$rootScope.cart = cart
		Page.loader.update()
		$rootScope.$apply()

	# Make pages global
	Moltin.Entry.List 'page', null, (pages) ->

		# Format data
		for k,v of pages
			$rootScope.pages[v.slug] = v

		# Assign data
		Page.loader.update()
		$rootScope.$apply()

	return null
]