module.exports = (grunt) ->

  # Config
  grunt.initConfig
    pkg: grunt.file.readJSON 'package.json'

    # Coffee -> JS
    coffee:
      compile:
        options:
          bare: true
          sourceMap: true
          sourceMapDir: 'build/'
        files:
          'build/store.js': ['src/coffee/app.coffee', 'src/coffee/factory.coffee', 'src/coffee/directive.coffee', 'src/coffee/pages/*.coffee', 'src/coffee/run.coffee']

    # JS Tests
    karma:
      unit:
        options:
          background: true
          files: ['test/*.js']

    # HTML 2 JS
    html2js:
      options:
        htmlmin:
          collapseBooleanAttributes: true
          collapseWhitespace: true
          removeAttributeQuotes: true
          removeComments: true
          removeEmptyAttributes: true
          removeScriptTypeAttributes: true
          removeStyleLinkTypeAttributes: true
        rename: (name) ->
          return name.replace 'html/', '/pages/'
      main:
        src: ['src/html/*.html', 'src/html/partials/*.html']
        dest: 'build/templates.js'

    # JS Concat
    concat:
      options:
        separator: ";\n"
      dist:
        src: ['src/libs/jquery-1.10.2.min.js', 'src/libs/bootstrap.min.js', 'src/libs/angular.min.js', 'src/libs/angular-*.js', 'src/libs/*.js', 'build/templates.js', 'build/store.js']
        dest: 'build/concat.js'

    # JS Minifier
    uglify:
      postCompile:
        options:
          mangle: true
          sourceMap: false
          drop_console: true
          banner: '/*! <%= pkg.name %> minified - v<%= pkg.version %> - ' +
          '<%= grunt.template.today("yyyy-mm-dd") %> */'
        files:
          'dist/js/store.min.js': ['build/concat.js']

    # CSS Minifier
    cssmin:
      compress:
        options:
          banner: '/* <%= pkg.name %> <%= grunt.template.today("dd-mm-yyyy") %> */'
        files:
          'dist/css/store.min.css': ['src/css/*.css']

    # Watch Config
    watch:
      files: ['src/coffee/*.coffee', 'src/coffee/pages/*.coffee', 'src/libs/*.js', 'src/css/*.css', 'src/html/*.html']
      tasks: ['coffee', 'karma', 'html2js', 'concat', 'uglify', 'cssmin']

  # These plugins provide necessary tasks
  grunt.loadNpmTasks 'grunt-contrib-cssmin'
  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-contrib-uglify'
  grunt.loadNpmTasks 'grunt-contrib-concat'
  grunt.loadNpmTasks 'grunt-html2js'
  grunt.loadNpmTasks 'grunt-uncss'
  grunt.loadNpmTasks 'grunt-karma'
  grunt.loadNpmTasks 'grunt-contrib-watch'

  # Default task
  grunt.registerTask 'default', ['coffee', 'karma', 'html2js', 'concat', 'uglify', 'cssmin']