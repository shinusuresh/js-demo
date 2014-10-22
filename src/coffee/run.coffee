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