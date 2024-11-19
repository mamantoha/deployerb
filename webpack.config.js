const path = require('path');
const webpack = require('webpack');
const MiniCssExtractPlugin = require('mini-css-extract-plugin');

const jsOutputTemplate = 'javascripts/[name].js';
const cssOutputTemplate = 'stylesheets/[name].css';

const config = {
  watchOptions: {
    aggregateTimeout: 300,
    poll: 1000,
    ignored: /node_modules/,
  },

  context: path.join(__dirname, '/app/assets'),

  entry: {
    application: ['./javascripts/application.js', './stylesheets/application.sass'],
  },

  output: {
    path: path.resolve(__dirname, 'public'),
    filename: jsOutputTemplate,
    clean: true,
  },

  module: {
    rules: [
      {
        test: /\.css$/,
        use: [MiniCssExtractPlugin.loader, 'css-loader'],
      },
      {
        test: /\.sass$/,
        use: [MiniCssExtractPlugin.loader, 'css-loader', 'sass-loader'],
      },
      {
        test: /bootstrap-sass\/assets\/javascripts\//,
        use: {
          loader: 'imports-loader',
          options: {
            additionalCode: 'var jQuery = require("jquery");',
          },
        },
      },
      {
        test: /\.(woff2?|svg)$/,
        type: 'asset',
        generator: {
          filename: 'fonts/[name][ext][query]',
        },
        parser: {
          dataUrlCondition: {
            maxSize: 10000,
          },
        },
      },
      {
        test: /\.(ttf|eot)$/,
        type: 'asset/resource',
        generator: {
          filename: 'fonts/[name][ext][query]',
        },
      },
    ],
  },

  plugins: [
    new MiniCssExtractPlugin({
      filename: cssOutputTemplate,
    }),
    new webpack.ProvidePlugin({
      $: 'jquery',
      jQuery: 'jquery',
      'window.jQuery': 'jquery',
    }),
  ],

  optimization: {
    splitChunks: {
      chunks: 'all',
      cacheGroups: {
        vendors: {
          test: /[\\/]node_modules[\\/]/,
          name: 'vendors',
          chunks: 'all',
        },
      },
    },
  },

  mode: process.env.NODE_ENV || 'development',
};

module.exports = config;
