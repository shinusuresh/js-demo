##########
## CART ##
##########

app.controller 'cartController', ['$scope', 'Moltin', 'Page', ($scope, Moltin, Page) ->

	# Page setup
	Page.titleSet 'Shopping Cart'

	return null
]
