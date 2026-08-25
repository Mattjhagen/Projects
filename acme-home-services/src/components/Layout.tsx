import { ReactNode } from 'react';
import Head from 'next/head';
import Navbar from './Navbar';

interface LayoutProps {
  children: ReactNode;
  title?: string;
  description?: string;
}

export default function Layout({ children, title, description }: LayoutProps) {
  return (
    <div className="min-h-screen flex flex-col">
      <Head>
        <title>{title || 'Acme Home Services'}</title>
        <meta name="description" content={description || 'Reliable plumbing and HVAC services in Chicago'} />
        <link rel="icon" href="/favicon.ico" />
      </Head>

      <Navbar />
      
      <main className="flex-grow">
        {children}
      </main>
      
      <footer className="bg-amber-800 text-white py-6">
        <div className="container mx-auto px-4">
          <div className="flex flex-col md:flex-row justify-between items-center">
            <p>© {new Date().getFullYear()} Acme Home Services. All rights reserved.</p>
            <div className="flex space-x-4 mt-4 md:mt-0">
              <a href="#" className="hover:text-amber-200 transition">Privacy Policy</a>
              <a href="#" className="hover:text-amber-200 transition">Terms of Service</a>
            </div>
          </div>
        </div>
      </footer>
    </div>
  );
}
