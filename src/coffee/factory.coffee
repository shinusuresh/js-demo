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
