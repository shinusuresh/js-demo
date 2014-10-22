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
