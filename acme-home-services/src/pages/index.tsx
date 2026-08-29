import Layout from '@/components/Layout';
import Link from 'next/link';

export default function Home() {
  return (
    <Layout 
      title="Acme Home Services - Plumbing & HVAC in Chicago"
      description="Reliable plumbing and HVAC services in Chicago"
    >
      <main className="container mx-auto px-4 py-8">
        <h1 className="text-4xl font-bold text-amber-800 mb-6">Welcome to Acme Home Services</h1>
        <p className="text-xl text-amber-700 mb-8">Chicago's trusted plumbing and HVAC specialists since 1995.</p>
        
        <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
          <div className="bg-white p-6 rounded-lg shadow-md">
            <h2 className="text-2xl font-semibold text-amber-800 mb-4">Emergency Services</h2>
            <p className="text-amber-700">24/7 emergency plumbing and HVAC services available.</p>
          </div>
          
          <div className="bg-white p-6 rounded-lg shadow-md">
            <h2 className="text-2xl font-semibold text-amber-800 mb-4">Schedule Service</h2>
            <p className="text-amber-700 mb-4">Book an appointment online or call us today.</p>
            <Link href="/contact" className="bg-amber-600 text-white px-4 py-2 rounded hover:bg-amber-700 transition">
              Contact Us
            </Link>
          </div>
        </div>
      </main>
    </Layout>
  );
}
