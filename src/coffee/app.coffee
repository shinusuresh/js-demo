####################
## DEMO STORE APP ##
####################

# Start the app
app = angular.module 'store', ['ngRoute', 'ngSanitize', 'ui.bootstrap', 'templates-main', 'ImageZoom']

# Config
app.value 'siteName', 'Molkea'
app.value 'publicKey', 'umRG34nxZVGIuCSPfYf8biBSvtABgTR8GMUtflyE'
app.value 'analyticsHost', 'http://analytics-thoughtservice.rhcloud.com:8080/'

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
