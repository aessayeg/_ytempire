/**
 * App.js - Main application component
 * YTEmpire Project
 */

import React from 'react';
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import { Provider } from 'react-redux';
import { QueryClient, QueryClientProvider } from 'react-query';
import { AuthProvider } from './context/AuthContext';
import { ThemeProvider } from './context/ThemeContext';
import { NotificationProvider } from './context/NotificationContext';
import { store } from './store';

// Pages
import Home from './pages/Home';
import Dashboard from './pages/Dashboard';
import Login from './pages/Login';
import Register from './pages/Register';
import Channels from './pages/Channels';
import Videos from './pages/Videos';
import Content from './pages/Content';
import Analytics from './pages/Analytics';
import Automation from './pages/Automation';
import Settings from './pages/Settings';
import Profile from './pages/Profile';

// Common Components
import Header from './components/common/Header';
import Footer from './components/common/Footer';
import ErrorBoundary from './components/common/ErrorBoundary';

const queryClient = new QueryClient();

function App() {
  return (
    <ErrorBoundary>
      <Provider store={store}>
        <QueryClientProvider client={queryClient}>
          <AuthProvider>
            <ThemeProvider>
              <NotificationProvider>
                <Router>
                  <div className="app">
                    <Header />
                    <main className="main-content">
                      <Routes>
                        <Route path="/" element={<Home />} />
                        <Route path="/dashboard" element={<Dashboard />} />
                        <Route path="/login" element={<Login />} />
                        <Route path="/register" element={<Register />} />
                        <Route path="/channels" element={<Channels />} />
                        <Route path="/videos" element={<Videos />} />
                        <Route path="/content" element={<Content />} />
                        <Route path="/analytics" element={<Analytics />} />
                        <Route path="/automation" element={<Automation />} />
                        <Route path="/settings" element={<Settings />} />
                        <Route path="/profile" element={<Profile />} />
                      </Routes>
                    </main>
                    <Footer />
                  </div>
                </Router>
              </NotificationProvider>
            </ThemeProvider>
          </AuthProvider>
        </QueryClientProvider>
      </Provider>
    </ErrorBoundary>
  );
}

export default App;
