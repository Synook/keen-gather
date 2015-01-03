module.exports = (grunt) ->

  grunt.initConfig
    pkg: grunt.file.readJSON 'package.json'
    coffee:
      compile:
        files:
          'public/main.js': ['src/*.coffee']
    copy:
      main:
        expand: true,
        cwd: 'src/',
        src: '*.html',
        dest: 'public/',
        flatten: true
    run:
      server:
        cmd: 'coffee',
        args: ['server.coffee']

  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-contrib-copy'
  grunt.loadNpmTasks 'grunt-run'

  grunt.registerTask 'default', ['coffee', 'copy', 'run:server']