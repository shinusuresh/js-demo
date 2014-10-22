var app;

app = angular.module('store', ['ngRoute', 'ngSanitize', 'ui.bootstrap', 'templates-main', 'ImageZoom']);

app.value('siteName', 'YOUR_STORE');

app.value('publicKey', 'YOUR_PUBLIC_KEY');

app.config([
  '$routeProvider', '$locationProvider', function($routeProvider, $locationProvider) {
    $locationProvider.html5Mode(true);
    $routeProvider.when('/', {
      templateUrl: '/pages/home.html',
      controller: 'homeController'
    }).when('/category/:slug', {
      templateUrl: '/pages/category.html',
      controller: 'categoryController'
    }).when('/collections', {
      templateUrl: '/pages/collections.html',
      controller: 'collectionsController'
    }).when('/collection/:slug', {
      templateUrl: '/pages/collection.html',
      controller: 'collectionController'
    }).when('/brand/:slug', {
      templateUrl: '/pages/brand.html',
      controller: 'brandController'
    }).when('/product/:slug', {
      templateUrl: '/pages/product.html',
      controller: 'productController'
    }).when('/search/:term?', {
      templateUrl: '/pages/search.html',
      controller: 'searchController'
    }).when('/cart', {
      templateUrl: '/pages/cart.html',
      controller: 'cartController'
    }).when('/checkout/payment', {
      templateUrl: '/pages/payment.html',
      controller: 'paymentController'
    }).when('/checkout/:status', {
      templateUrl: '/pages/complete.html',
      controller: 'completeController'
    }).when('/checkout', {
      templateUrl: '/pages/checkout.html',
      controller: 'checkoutController'
    }).when('/error', {
      templateUrl: '/pages/error.html',
      controller: 'errorController'
    }).when('/:page*', {
      templateUrl: '/pages/page.html',
      controller: 'pageController'
    });
    return null;
  }
]);

app.factory('Moltin', [
  '$rootScope', '$location', 'publicKey', function($rootScope, $location, publicKey) {
    var moltin;
    moltin = new Moltin({
      publicId: publicKey,
      notice: function(type, msg, code) {
        var data, e, k, p, v;
        if (code === '404') {
          $rootScope.error = code;
          $location.path('/error');
        } else {
          $rootScope.notices = [];
          type = type === 'error' ? 'danger' : type;
          if (typeof msg === 'string') {
            $rootScope.notices.push({
              type: type,
              msg: msg
            });
          } else {
            for (e in msg) {
              p = msg[e];
              data = '';
              if (typeof p === 'string') {
                data = p;
              } else {
                for (k in p) {
                  v = p[k];
                  data += v + '<br />';
                }
              }
              $rootScope.notices.push({
                type: type,
                msg: data
              });
            }
          }
        }
        return $rootScope.$apply();
      }
    });
    return moltin.Authenticate();
  }
]);

app.factory('Page', [
  '$rootScope', '$location', 'Moltin', 'siteName', function($rootScope, $location, Moltin, siteName) {
    var first;
    $rootScope.siteName = siteName;
    $rootScope.title = 'Home';
    $rootScope.notices = [];
    $rootScope.term = '';
    $rootScope.loader = {
      todo: 0,
      done: 0
    };
    $rootScope.cache = {
      product: {},
      category: {}
    };
    $rootScope.$on('$routeChangeStart', function(next, current) {
      return $rootScope.notices = [];
    });
    first = function(obj) {
      return obj[Object.keys(obj)[0]];
    };
    return {
      titleSet: function(newTitle) {
        return $rootScope.title = newTitle;
      },
      currencySet: function(currency) {
        return Moltin.Currency.Set(currency, function(data) {
          return window.location.reload();
        });
      },
      search: function(term) {
        return $location.path('/search/' + term);
      },
      image: {
        resize: function(image, h, w, type) {
          if (type == null) {
            type = 'fit';
          }
          return 'http://' + image.segments.domain + '/w' + w + '/h' + h + '/' + (type !== '' ? type + '/' : '') + image.segments.suffix;
        }
      },
      notice: {
        set: function(type, msg) {
          return $rootScope.notices.push({
            type: type,
            msg: msg
          });
        },
        dismiss: function(key) {
          return $rootScope.notices.splice(key, 1);
        }
      },
      loader: {
        set: function(num) {
          $rootScope.loader = {
            todo: num,
            done: 0
          };
          return setTimeout(function() {
            return $rootScope.loader = {
              todo: 0,
              done: 0
            };
          }, 3000);
        },
        update: function() {
          return $rootScope.loader.done++;
        }
      },
      format: {
        category: function(category) {
          category.image = Object.keys(category.images).length > 0 ? first(category.images) : {
            url: {
              http: '/img/no-img.jpg',
              https: '/img/no-img.jpg'
            }
          };
          $rootScope.cache.category[category.slug] = category;
          return category;
        },
        collection: function(collection) {
          collection.image = Object.keys(collection.images).length > 0 ? first(collection.images) : {
            url: {
              http: '/img/no-img.jpg',
              https: '/img/no-img.jpg'
            }
          };
          return collection;
        },
        product: function(product) {
          product.category = first(product.category.data);
          product.image = Object.keys(product.images).length > 0 ? first(product.images) : {
            url: {
              http: '/img/no-img.jpg',
              https: '/img/no-img.jpg'
            }
          };
          $rootScope.cache.product[product.slug] = product;
          return product;
        }
      }
    };
  }
]);

app.directive('slideshow', function() {
  return function(scope, el, attrs) {
    return $(el).camera({
      imagePath: '/img/slideshow/'
    });
  };
});

app.directive('cardFormat', function() {
  return function(scope, el, attrs) {
    return el.bind('keyup focus blur', function() {
      return $(this).val(function(i, v) {
        v = v.replace(/[^\d]/g, '').match(/.{1,4}/g);
        return (v ? v.join(' ') : '').substr(0, 19);
      });
    });
  };
});

app.directive('cartInsert', [
  '$rootScope', 'Moltin', 'Page', function($rootScope, Moltin, Page) {
    return function(scope, el, attrs) {
      return el.bind('click', function() {
        var ex, id, mod, qty;
        id = attrs.ngId;
        qty = 1;
        mod = {};
        ex = false;
        if (typeof attrs.ngQty !== 'undefined') {
          if (isNaN(attrs.ngQty)) {
            qty = $(attrs.ngQty).val() > 0 ? $(attrs.ngQty).val() : 1;
          } else {
            qty = attrs.ngQty;
          }
        }
        if (typeof attrs.ngMod !== 'undefined') {
          $rootScope.notices = [];
          $(attrs.ngMod + ' select').each(function() {
            if ($(this).val() <= 0) {
              Page.notice.set('warning', 'Please select a ' + $(this).attr('title') + ' option before adding to cart');
              ex = true;
              return null;
            }
            return mod[$(this).attr('ng-mod')] = $(this).val();
          });
        }
        if (ex) {
          return null;
        }
        return Moltin.Cart.Insert(id, qty, mod, function(response) {
          return Moltin.Cart.Contents(function(cart) {
            var k, v, _ref;
            _ref = cart.contents;
            for (k in _ref) {
              v = _ref[k];
              cart.contents[k] = Page.format.product(v);
            }
            $("html, body").animate({
              scrollTop: 0
            }, 150);
            $('.navbar-right > .cart').addClass('added');
            setTimeout(function() {
              return $('.navbar-right > .cart').removeClass('added');
            }, 1000);
            $rootScope.cart = cart;
            return $rootScope.$apply();
          });
        });
      });
    };
  }
]);

app.directive('cartQty', [
  '$rootScope', 'Moltin', 'Page', function($rootScope, Moltin, Page) {
    return function(scope, el, attrs) {
      return el.bind('click', function() {
        var id, qty;
        id = attrs.ngId;
        qty = 1;
        if (typeof attrs.ngQty !== 'undefined') {
          if (isNaN(attrs.ngQty)) {
            qty = $(attrs.ngQty).val() > 0 ? $(attrs.ngQty).val() : 1;
          } else {
            qty = attrs.ngQty;
          }
        }
        return Moltin.Cart.Update(id, {
          quantity: qty
        }, function(response) {
          return Moltin.Cart.Contents(function(cart) {
            var k, v, _ref;
            _ref = cart.contents;
            for (k in _ref) {
              v = _ref[k];
              cart.contents[k] = Page.format.product(v);
            }
            $rootScope.cart = cart;
            return $rootScope.$apply();
          });
        });
      });
    };
  }
]);

app.controller('brandController', [
  '$scope', '$routeParams', 'Moltin', 'Page', function($scope, $routeParams, Moltin, Page) {
    $scope.pageCurrent = 0;
    $scope.pagination = {
      total: 0,
      limit: 12,
      offset: 0
    };
    Page.loader.set(2);
    $scope.$watch('pageCurrent', function(n, o) {
      if ($scope.brand) {
        Page.loader.set(1);
        return $scope.pageChange(n);
      }
    });
    $scope.pageChange = function(page) {
      $scope.pagination.offset = page > 1 ? (page - 1) * $scope.pagination.limit : 0;
      return Moltin.Product.List({
        brand: $scope.brand.id,
        status: 1,
        limit: $scope.pagination.limit,
        offset: $scope.pagination.offset
      }, function(products, pagination) {
        var k, v;
        if (products.length <= 0) {
          Page.notice.set('info', 'No products found in "' + $scope.brand.title + '"');
        } else {
          for (k in products) {
            v = products[k];
            products[k] = Page.format.product(v);
          }
        }
        $scope.products = products;
        $scope.pagination = pagination;
        Page.loader.update();
        return $scope.$apply();
      });
    };
    Moltin.Brand.Find({
      slug: $routeParams.slug,
      status: 1
    }, function(brand) {
      Page.titleSet(brand.title);
      $scope.brand = brand;
      Page.loader.update();
      $scope.$apply();
      return $scope.pageChange(1);
    });
    return null;
  }
]);

app.controller('cartController', [
  '$scope', 'Moltin', 'Page', function($scope, Moltin, Page) {
    Page.titleSet('Shopping Cart');
    return null;
  }
]);

app.controller('categoryController', [
  '$scope', '$routeParams', 'Moltin', 'Page', function($scope, $routeParams, Moltin, Page) {
    $scope.pageCurrent = 0;
    $scope.pagination = {
      total: 0,
      limit: 12,
      offset: 0
    };
    Page.loader.set(2);
    $scope.$watch('pageCurrent', function(n, o) {
      if ($scope.category) {
        Page.loader.set(1);
        return $scope.pageChange(n);
      }
    });
    $scope.pageChange = function(page) {
      $scope.pagination.offset = page > 1 ? (page - 1) * $scope.pagination.limit : 0;
      return Moltin.Product.List({
        category: $scope.category.id,
        status: 1,
        limit: $scope.pagination.limit,
        offset: $scope.pagination.offset
      }, function(products, pagination) {
        var k, v;
        if (products.length <= 0) {
          Page.notice.set('info', 'No products found in "' + $scope.category.title + '"');
        } else {
          for (k in products) {
            v = products[k];
            products[k] = Page.format.product(v);
          }
        }
        $scope.products = products;
        $scope.pagination = pagination;
        Page.loader.update();
        return $scope.$apply();
      });
    };
    Moltin.Category.Find({
      slug: $routeParams.slug,
      status: 1
    }, function(category) {
      Page.titleSet(category.title);
      $scope.category = category;
      Page.loader.update();
      $scope.$apply();
      return $scope.pageChange(1);
    });
    return null;
  }
]);

app.controller('checkoutController', [
  '$scope', '$routeParams', '$rootScope', '$location', 'Moltin', 'Page', function($scope, $routeParams, $rootScope, $location, Moltin, Page) {
    Page.titleSet('Checkout');
    $scope.customer = 919;
    $scope.data = {
      bill: {},
      ship: {},
      ship_bill: 0,
      notes: '',
      shipping: '',
      gateway: ''
    };
    Page.loader.set(2);
    $scope.createOrder = function(data) {
      $scope.data.bill.customer = $scope.customer;
      $scope.data.ship.customer = $scope.customer;
      console.log($scope.data);
      return Moltin.Cart.Complete({
        customer: $scope.customer,
        gateway: $scope.data.gateway,
        shipping: $scope.data.shipping,
        bill_to: $scope.data.bill,
        ship_to: $scope.data.ship_bill ? 'bill_to' : $scope.data.ship
      }, function(response) {
        $rootScope.order = response;
        $rootScope.$apply(function() {
          return $location.path('/checkout/payment');
        });
        return null;
      });
    };
    Moltin.Cart.Checkout(function(options) {
      $scope.options = options;
      Page.loader.update();
      return $scope.$apply();
    });
    Moltin.Address.Fields($scope.customer, 0, function(fields) {
      $scope.fields = fields;
      Page.loader.update();
      return $scope.$apply();
    });
    return null;
  }
]);

app.controller('collectionController', [
  '$scope', '$routeParams', 'Moltin', 'Page', function($scope, $routeParams, Moltin, Page) {
    $scope.pageCurrent = 0;
    $scope.pagination = {
      total: 0,
      limit: 12,
      offset: 0
    };
    Page.loader.set(2);
    $scope.$watch('pageCurrent', function(n, o) {
      if ($scope.collection) {
        Page.loader.set(1);
        return $scope.pageChange(n);
      }
    });
    $scope.pageChange = function(page) {
      $scope.pagination.offset = page > 1 ? (page - 1) * $scope.pagination.limit : 0;
      return Moltin.Product.List({
        collection: $scope.collection.id,
        status: 1,
        limit: $scope.pagination.limit,
        offset: $scope.pagination.offset
      }, function(products, pagination) {
        var k, v;
        if (products.length <= 0) {
          Page.notice.set('info', 'No products found in "' + $scope.collection.title + '"');
        } else {
          for (k in products) {
            v = products[k];
            products[k] = Page.format.product(v);
          }
        }
        $scope.products = products;
        $scope.pagination = pagination;
        Page.loader.update();
        return $scope.$apply();
      });
    };
    Moltin.Collection.Find({
      slug: $routeParams.slug,
      status: 1
    }, function(collection) {
      Page.titleSet(collection.title);
      $scope.collection = Page.format.collection(collection);
      Page.loader.update();
      $scope.$apply();
      return $scope.pageChange(1);
    });
    return null;
  }
]);

app.controller('collectionsController', [
  '$scope', 'Moltin', 'Page', function($scope, Moltin, Page) {
    Page.titleSet('Collections');
    Page.loader.set(1);
    Moltin.Collection.List({
      status: 1,
      limit: 9
    }, function(collections, pagination) {
      var k, v;
      for (k in collections) {
        v = collections[k];
        collections[k] = Page.format.collection(v);
      }
      $scope.collections = collections;
      Page.loader.update();
      return $scope.$apply();
    });
    return null;
  }
]);

app.controller('completeController', [
  '$scope', '$routeParams', '$location', 'Moltin', 'Page', function($scope, $routeParams, $location, Moltin, Page) {
    if (typeof $scope.payment === 'undefined') {
      $location.path('/payment');
    }
    Page.titleSet($scope.payment.message);
    Page.notice.set('success', $scope.payment.message);
    return null;
  }
]);

app.controller('errorController', [
  '$scope', '$routeParams', '$location', 'Page', function($scope, $routeParams, $location, Page) {
    if ($scope.error === '404') {
      $scope.message = {
        type: '404',
        title: 'Page not found',
        msg: 'We\'re sorry, the page you are looking for might have been removed, had its name changed or is temporarily unavailable.'
      };
    } else {
      $location.path('/');
    }
    return null;
  }
]);

app.controller('homeController', [
  '$scope', '$route', 'Moltin', 'Page', function($scope, $route, Moltin, Page) {
    Page.titleSet('Home');
    Page.loader.set(3);
    Moltin.Product.Search({
      featured: 1,
      status: 1,
      limit: 9
    }, function(products) {
      var k, v;
      for (k in products) {
        v = products[k];
        products[k] = Page.format.product(v);
      }
      $scope.products = products;
      Page.loader.update();
      return $scope.$apply();
    });
    Moltin.Collection.List({
      status: 1,
      limit: 10
    }, function(collections) {
      $scope.collections = collections;
      Page.loader.update();
      return $scope.$apply();
    });
    Moltin.Currency.List({
      enabled: '1'
    }, function(currencies) {
      $scope.currencies = currencies;
      Page.loader.update();
      return $scope.$apply();
    });
    return null;
  }
]);

app.controller('pageController', [
  '$scope', '$routeParams', '$location', 'Page', function($scope, $routeParams, $location, Page) {
    $scope.$watchCollection('pages', function() {
      var page;
      if (typeof $scope.pages[$routeParams.page] !== 'undefined') {
        page = $scope.pages[$routeParams.page];
        Page.titleSet(page.title);
        $scope.content = page;
        if (!$scope.$$phase) {
          return $scope.$apply();
        }
      } else if (Object.keys($scope.pages).length > 0) {
        return $location.path('/error');
      }
    });
    return null;
  }
]);

app.controller('paymentController', [
  '$scope', '$routeParams', '$rootScope', '$location', 'Moltin', 'Page', function($scope, $routeParams, $rootScope, $location, Moltin, Page) {
    if (typeof $scope.order === 'undefined' || $scope.order.id < 0) {
      $location.path('/checkout');
    }
    console.log($scope.order);
    Page.titleSet('Payment');
    $scope.data = {
      number: '4242 4242 4242 4242',
      expiry_month: '05',
      expiry_year: '2015',
      start_month: '04',
      start_year: '2014',
      cvv: '123'
    };
    $scope.payment = function(data) {
      return Moltin.Checkout.Payment('purchase', $scope.order.id, {
        data: $scope.data
      }, function(response) {
        delete $rootScope.order;
        $rootScope.payment = response;
        return $rootScope.$apply(function() {
          return $location.path('/checkout/complete');
        });
      });
    };
    return null;
  }
]);

app.controller('productController', [
  '$rootScope', '$scope', '$routeParams', 'Moltin', 'Page', function($rootScope, $scope, $routeParams, Moltin, Page) {
    $scope.mods = {};
    $scope.switchImage = function(src) {
      return $scope.imageSrc = src;
    };
    $scope.display = function(product) {
      var k, v, _ref;
      console.log(product);
      Page.titleSet(product.title);
      if (typeof product.image === 'undefined') {
        $scope.product = Page.format.product(product);
        Page.loader.update();
      } else {
        $scope.product = product;
      }
      if (!$scope.$$phase) {
        $scope.$apply();
      }
      if (Object.keys(product.modifiers).length > 0) {
        $scope.modifiers = product.modifiers;
        _ref = product.modifiers;
        for (k in _ref) {
          v = _ref[k];
          $scope.mods[k] = 0;
        }
      }
      $scope.$watch('mods', function(n, o) {
        var params, set;
        if (Object.keys(n).length < 1 || JSON.stringify(n) === JSON.stringify(o)) {
          return false;
        }
        set = true;
        params = {
          status: 1,
          modifier: {}
        };
        for (k in n) {
          v = n[k];
          if (v === '0' || v === 0) {
            set = false;
          } else {
            params.modifier[k] = v;
          }
        }
        if (!set) {
          delete params.modifier;
          params.slug = $routeParams.slug;
        }
        if (typeof params.modifier === 'undefined' && $scope.cache.product[$routeParams.slug] !== 'undefined') {
          $scope.product = $scope.cache.product[$routeParams.slug];
          if (!$scope.$$phase) {
            return $scope.$apply();
          }
        } else {
          return Moltin.Product.Find(params, function(product) {
            $scope.product = Page.format.product(product);
            return $scope.$apply();
          });
        }
      }, true);
      return Moltin.Product.Search({
        category: $scope.product.category.id,
        status: 1,
        limit: 5
      }, function(items) {
        var products;
        products = [];
        for (k in items) {
          v = items[k];
          if (v.id !== $scope.product.id && products.length < 4) {
            products.push(Page.format.product(v));
          }
        }
        $scope.products = products;
        if (!$scope.$$phase) {
          return $scope.$apply();
        }
      });
    };
    if (Object.keys($scope.cache.product).length > 0 && typeof $scope.cache.product[$routeParams.slug] !== 'undefined') {
      $scope.display($scope.cache.product[$routeParams.slug]);
    } else {
      Page.loader.set(1);
      Moltin.Product.Find({
        slug: $routeParams.slug,
        status: 1
      }, $scope.display);
    }
    return null;
  }
]);

app.controller('searchController', [
  '$scope', '$routeParams', 'Moltin', 'Page', function($scope, $routeParams, Moltin, Page) {
    if (typeof $routeParams.term !== 'undefined') {
      Page.titleSet('Search "' + $routeParams.term + '"');
      $scope.term = $routeParams.term;
      $scope.search = $routeParams.term;
      Moltin.Product.Search({
        title: $scope.search,
        status: 1,
        limit: 9
      }, function(products) {
        var k, v;
        for (k in products) {
          v = products[k];
          products[k] = Page.format.product(v);
        }
        $scope.products = products;
        return $scope.$apply();
      });
    } else {
      Page.titleSet('Search');
    }
    return null;
  }
]);

app.run([
  '$rootScope', 'Moltin', 'Page', function($rootScope, Moltin, Page) {
    $rootScope.currency = Moltin.options.currency !== false ? Moltin.options.currency : 'GBP';
    $rootScope.pages = {};
    $rootScope.Page = Page;
    Page.loader.set(3);
    Moltin.Category.Tree({
      status: 1
    }, function(categories) {
      $rootScope.categories = categories;
      Page.loader.update();
      return $rootScope.$apply();
    });
    Moltin.Cart.Contents(function(cart) {
      var k, v, _ref;
      _ref = cart.contents;
      for (k in _ref) {
        v = _ref[k];
        cart.contents[k] = Page.format.product(v);
      }
      $rootScope.cart = cart;
      Page.loader.update();
      return $rootScope.$apply();
    });
    Moltin.Entry.List('page', null, function(pages) {
      var k, v;
      for (k in pages) {
        v = pages[k];
        $rootScope.pages[v.slug] = v;
      }
      Page.loader.update();
      return $rootScope.$apply();
    });
    return null;
  }
]);

//# sourceMappingURL=store.js.map
