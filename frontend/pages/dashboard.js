import React, { useState, useEffect } from 'react';
import Head from 'next/head';
import Link from 'next/link';
import { useRouter } from 'next/router';

// Import existing components
import DashboardLayout from '../src/components/dashboard/DashboardLayout';
import StatsCard from '../src/components/dashboard/StatsCard';
import RecentActivity from '../src/components/dashboard/RecentActivity';
import QuickActions from '../src/components/dashboard/QuickActions';
import PerformanceChart from '../src/components/analytics/PerformanceChart';

export default function Dashboard() {
  const router = useRouter();
  const [loading, setLoading] = useState(true);
  const [stats, setStats] = useState({
    totalViews: 0,
    subscribers: 0,
    videos: 0,
    engagement: 0,
  });

  useEffect(() => {
    // Simulate fetching dashboard data
    const fetchDashboardData = async () => {
      try {
        // In production, this would be an API call
        // const response = await fetch('/api/dashboard');
        // const data = await response.json();

        // Mock data for now
        setTimeout(() => {
          setStats({
            totalViews: 1250000,
            subscribers: 45200,
            videos: 142,
            engagement: 4.8,
          });
          setLoading(false);
        }, 1000);
      } catch (error) {
        console.error('Error fetching dashboard data:', error);
        setLoading(false);
      }
    };

    fetchDashboardData();
  }, []);

  return (
    <>
      <Head>
        <title>Dashboard - YTEmpire</title>
        <meta name="description" content="YTEmpire Dashboard - Manage your YouTube empire" />
      </Head>

      <DashboardLayout>
        <div className="p-6">
          {/* Header */}
          <div className="mb-8">
            <h1 className="text-3xl font-bold text-gray-900">Dashboard</h1>
            <p className="text-gray-600 mt-2">Welcome back! Here&apos;s your channel overview.</p>
          </div>

          {/* Stats Grid */}
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
            <StatsCard
              title="Total Views"
              value={loading ? '...' : stats.totalViews.toLocaleString()}
              change="+12.5%"
              trend="up"
              icon={
                <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={2}
                    d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"
                  />
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={2}
                    d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"
                  />
                </svg>
              }
            />
            <StatsCard
              title="Subscribers"
              value={loading ? '...' : stats.subscribers.toLocaleString()}
              change="+8.2%"
              trend="up"
              icon={
                <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={2}
                    d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z"
                  />
                </svg>
              }
            />
            <StatsCard
              title="Videos"
              value={loading ? '...' : stats.videos.toString()}
              change="+3"
              trend="up"
              icon={
                <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={2}
                    d="M15 10l4.553-2.276A1 1 0 0121 8.618v6.764a1 1 0 01-1.447.894L15 14M5 18h8a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v8a2 2 0 002 2z"
                  />
                </svg>
              }
            />
            <StatsCard
              title="Engagement Rate"
              value={loading ? '...' : `${stats.engagement}%`}
              change="-0.5%"
              trend="down"
              icon={
                <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={2}
                    d="M13 7h8m0 0v8m0-8l-8 8-4-4-6 6"
                  />
                </svg>
              }
            />
          </div>

          {/* Charts and Activity */}
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
            {/* Performance Chart */}
            <div className="lg:col-span-2">
              <div className="bg-white rounded-lg shadow p-6">
                <h2 className="text-lg font-semibold mb-4">Channel Performance</h2>
                <PerformanceChart />
              </div>
            </div>

            {/* Recent Activity */}
            <div className="lg:col-span-1">
              <div className="bg-white rounded-lg shadow p-6">
                <h2 className="text-lg font-semibold mb-4">Recent Activity</h2>
                <RecentActivity />
              </div>
            </div>
          </div>

          {/* Quick Actions */}
          <div className="mt-8">
            <h2 className="text-lg font-semibold mb-4">Quick Actions</h2>
            <QuickActions />
          </div>
        </div>
      </DashboardLayout>
    </>
  );
}
