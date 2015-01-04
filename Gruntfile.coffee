module.exports = (grunt) ->

  grunt.initConfig
    pkg: grunt.file.readJSON 'package.json'
    coffee:
      compile:
        files:
          'public/main.js': ['src/*.coffee']
          'server.js': ['server.coffee']
    less:
      main:
        files:
          'public/stylesheet.css': ['src/stylesheet.less']
    copy:
      main:
        expand: true,
        cwd: 'src/',
        src: '*.html',
        dest: 'public/',
        flatten: true
    run:
      server:
        cmd: 'node',
        args: ['server.js']

  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-contrib-less'
  grunt.loadNpmTasks 'grunt-contrib-copy'
  grunt.loadNpmTasks 'grunt-run'

  grunt.registerTask 'build', ['coffee', 'less', 'copy']
  grunt.registerTask 'default', ['build', 'run:server']
