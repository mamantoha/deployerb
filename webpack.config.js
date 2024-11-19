const path = require('path');
const MiniCssExtractPlugin = require('mini-css-extract-plugin');
const webpack = require('webpack');

module.exports = {
  // Entry point for JavaScript and Sass
  entry: {
    application: ['./app/assets/javascripts/application.js', './app/assets/stylesheets/application.sass'],
  },

  // Output configuration
  output: {
    path: path.resolve(__dirname, 'public'),
    filename: 'javascripts/[name].js', // Output JavaScript files
    clean: true, // Clean output directory before building
  },

  // Module rules for processing files
  module: {
    rules: [
      // JavaScript loader
      {
        test: /\.js$/,
        exclude: /node_modules/,
        use: {
          loader: 'babel-loader',
          options: {
            presets: ['@babel/preset-env'],
          },
        },
      },

      // CSS loader
      {
        test: /\.css$/,
        use: [MiniCssExtractPlugin.loader, 'css-loader'],
      },

      // Sass loader with resolve-url-loader for correct font paths
      {
        test: /\.(sass|scss)$/,
        use: [
          MiniCssExtractPlugin.loader,
          'css-loader',
          {
            loader: 'resolve-url-loader', // Resolves relative paths
          },
          {
            loader: 'sass-loader',
            options: {
              sassOptions: {
                includePaths: [path.resolve(__dirname, 'node_modules')],
              },
              sourceMap: true, // Required for resolve-url-loader
            },
          },
        ],
      },

      // Fonts and assets loader
      {
        test: /\.(woff2?|ttf|eot|svg)$/,
        type: 'asset/resource',
        generator: {
          filename: 'fonts/[name][ext][query]', // Output fonts to fonts/ directory
        },
      },
    ],
  },

  // Plugins
  plugins: [
    // Extract CSS into separate files
    new MiniCssExtractPlugin({
      filename: 'stylesheets/[name].css', // Output CSS to stylesheets/ directory
    }),

    // Provide jQuery globally for Bootstrap compatibility
    new webpack.ProvidePlugin({
      $: 'jquery',
      jQuery: 'jquery',
      'window.jQuery': 'jquery',
    }),
  ],

  // Resolve paths and extensions
  resolve: {
    modules: [
      path.resolve(__dirname, 'app/assets/stylesheets'), // Resolve custom styles
      'node_modules', // Resolve dependencies from node_modules
    ],
    extensions: ['.js', '.css', '.sass', '.scss'], // Supported extensions
  },

  // Development mode
  mode: 'development',

  // Watch options for live development
  watchOptions: {
    aggregateTimeout: 300,
    poll: 1000,
    ignored: /node_modules/,
  },
};
