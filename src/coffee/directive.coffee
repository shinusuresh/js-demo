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
