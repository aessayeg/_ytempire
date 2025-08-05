import React from 'react';
import Head from 'next/head';
import Link from 'next/link';
import { motion } from 'framer-motion';

export default function Home() {
  return (
    <>
      <Head>
        <title>YTEmpire - YouTube Analytics & Content Management Platform</title>
        <meta name="description" content="Enterprise-grade YouTube channel management and analytics platform" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <link rel="icon" href="/favicon.ico" />
      </Head>

      <div className="min-h-screen bg-gradient-to-br from-gray-900 via-purple-900 to-violet-900">
        {/* Navigation */}
        <nav className="flex justify-between items-center p-6 text-white">
          <div className="flex items-center space-x-2">
            <svg className="w-8 h-8" viewBox="0 0 24 24" fill="currentColor">
              <path d="M12 2L2 7v10c0 5.55 3.84 10.74 9 12 5.16-1.26 9-6.45 9-12V7l-10-5z"/>
            </svg>
            <span className="text-2xl font-bold">YTEmpire</span>
          </div>
          <div className="flex items-center space-x-6">
            <Link href="/login" className="hover:text-purple-300 transition">
              Login
            </Link>
            <Link href="/register" className="bg-purple-600 hover:bg-purple-700 px-4 py-2 rounded-lg transition">
              Get Started
            </Link>
          </div>
        </nav>

        {/* Hero Section */}
        <motion.div 
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6 }}
          className="container mx-auto px-6 py-20 text-center text-white"
        >
          <h1 className="text-5xl md:text-7xl font-bold mb-6">
            Master Your
            <span className="bg-gradient-to-r from-purple-400 to-pink-400 bg-clip-text text-transparent"> YouTube Empire</span>
          </h1>
          <p className="text-xl md:text-2xl mb-12 text-gray-300 max-w-3xl mx-auto">
            Professional YouTube analytics, content management, and growth automation platform for creators and agencies
          </p>
          
          <div className="flex flex-col md:flex-row gap-4 justify-center mb-20">
            <Link href="/register" className="bg-purple-600 hover:bg-purple-700 text-white px-8 py-4 rounded-lg text-lg font-semibold transition transform hover:scale-105">
              Start Free Trial
            </Link>
            <Link href="/demo" className="border border-purple-400 text-purple-400 hover:bg-purple-400 hover:text-white px-8 py-4 rounded-lg text-lg font-semibold transition">
              Watch Demo
            </Link>
          </div>

          {/* Features Grid */}
          <div className="grid md:grid-cols-3 gap-8 mt-20">
            <motion.div 
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.2 }}
              className="bg-white/10 backdrop-blur-lg rounded-xl p-6"
            >
              <div className="bg-purple-600 w-12 h-12 rounded-lg flex items-center justify-center mb-4 mx-auto">
                <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" />
                </svg>
              </div>
              <h3 className="text-xl font-semibold mb-2">Advanced Analytics</h3>
              <p className="text-gray-300">
                Real-time performance metrics, audience insights, and growth tracking across all your channels
              </p>
            </motion.div>

            <motion.div 
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.3 }}
              className="bg-white/10 backdrop-blur-lg rounded-xl p-6"
            >
              <div className="bg-purple-600 w-12 h-12 rounded-lg flex items-center justify-center mb-4 mx-auto">
                <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 10V3L4 14h7v7l9-11h-7z" />
                </svg>
              </div>
              <h3 className="text-xl font-semibold mb-2">Content Automation</h3>
              <p className="text-gray-300">
                Schedule uploads, automate thumbnails, and manage your content pipeline effortlessly
              </p>
            </motion.div>

            <motion.div 
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.4 }}
              className="bg-white/10 backdrop-blur-lg rounded-xl p-6"
            >
              <div className="bg-purple-600 w-12 h-12 rounded-lg flex items-center justify-center mb-4 mx-auto">
                <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z" />
                </svg>
              </div>
              <h3 className="text-xl font-semibold mb-2">Team Collaboration</h3>
              <p className="text-gray-300">
                Manage multiple channels with your team, assign roles, and streamline your workflow
              </p>
            </motion.div>
          </div>
        </motion.div>

        {/* Stats Section */}
        <div className="bg-black/30 backdrop-blur-lg py-16">
          <div className="container mx-auto px-6">
            <div className="grid md:grid-cols-4 gap-8 text-center text-white">
              <div>
                <div className="text-4xl font-bold text-purple-400">10K+</div>
                <div className="text-gray-300 mt-2">Active Creators</div>
              </div>
              <div>
                <div className="text-4xl font-bold text-purple-400">50M+</div>
                <div className="text-gray-300 mt-2">Videos Analyzed</div>
              </div>
              <div>
                <div className="text-4xl font-bold text-purple-400">2B+</div>
                <div className="text-gray-300 mt-2">Views Tracked</div>
              </div>
              <div>
                <div className="text-4xl font-bold text-purple-400">99.9%</div>
                <div className="text-gray-300 mt-2">Uptime</div>
              </div>
            </div>
          </div>
        </div>

        {/* CTA Section */}
        <div className="container mx-auto px-6 py-20 text-center">
          <motion.div
            initial={{ opacity: 0, scale: 0.9 }}
            animate={{ opacity: 1, scale: 1 }}
            transition={{ delay: 0.5 }}
            className="bg-gradient-to-r from-purple-600 to-pink-600 rounded-2xl p-12 text-white"
          >
            <h2 className="text-4xl font-bold mb-4">Ready to Scale Your YouTube Success?</h2>
            <p className="text-xl mb-8">Join thousands of creators using YTEmpire to grow their channels</p>
            <Link href="/register" className="bg-white text-purple-600 hover:bg-gray-100 px-8 py-4 rounded-lg text-lg font-semibold transition inline-block">
              Start Your Free Trial
            </Link>
            <p className="mt-4 text-sm">No credit card required • 14-day free trial</p>
          </motion.div>
        </div>

        {/* Footer */}
        <footer className="bg-black/50 backdrop-blur-lg text-white py-8">
          <div className="container mx-auto px-6">
            <div className="flex flex-col md:flex-row justify-between items-center">
              <div className="mb-4 md:mb-0">
                <span className="text-xl font-bold">YTEmpire</span>
                <p className="text-gray-400 mt-1">© 2025 YTEmpire. All rights reserved.</p>
              </div>
              <div className="flex space-x-6">
                <Link href="/privacy" className="text-gray-400 hover:text-white transition">
                  Privacy
                </Link>
                <Link href="/terms" className="text-gray-400 hover:text-white transition">
                  Terms
                </Link>
                <Link href="/docs" className="text-gray-400 hover:text-white transition">
                  Documentation
                </Link>
                <Link href="/support" className="text-gray-400 hover:text-white transition">
                  Support
                </Link>
              </div>
            </div>
          </div>
        </footer>
      </div>
    </>
  );
}