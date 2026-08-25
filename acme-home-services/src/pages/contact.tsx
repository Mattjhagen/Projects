import Layout from '@/components/Layout';
import Link from 'next/link';

export default function Contact() {
  return (
    <Layout 
      title="Contact Us - Acme Home Services"
      description="Get in touch with our team"
    >
      <main className="container mx-auto px-4 py-8">
        <h1 className="text-4xl font-bold text-amber-800 mb-6">Contact Acme Home Services</h1>
        
        <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
          <div className="bg-white p-6 rounded-lg shadow-md">
            <h2 className="text-2xl font-semibold text-amber-800 mb-4">Contact Information</h2>
            <div className="space-y-4 text-amber-700">
              <p>
                <span className="font-semibold">Phone:</span> (312) 555-1234
              </p>
              <p>
                <span className="font-semibold">Email:</span> info@acmehomeservices.com
              </p>
              <p>
                <span className="font-semibold">Address:</span> 123 Main St, Chicago, IL 60601
              </p>
              <p>
                <span className="font-semibold">Hours:</span> Mon-Fri 8am-6pm, Sat 9am-2pm
              </p>
            </div>
          </div>
          
          <div className="bg-white p-6 rounded-lg shadow-md">
            <h2 className="text-2xl font-semibold text-amber-800 mb-4">Send Us a Message</h2>
            <form className="space-y-4">
              <div>
                <label htmlFor="name" className="block text-sm font-medium text-amber-700">Name</label>
                <input 
                  type="text" 
                  id="name" 
                  className="mt-1 block w-full border border-amber-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-amber-500 focus:border-amber-500"
                />
              </div>
              <div>
                <label htmlFor="email" className="block text-sm font-medium text-amber-700">Email</label>
                <input 
                  type="email" 
                  id="email" 
                  className="mt-1 block w-full border border-amber-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-amber-500 focus:border-amber-500"
                />
              </div>
              <div>
                <label htmlFor="message" className="block text-sm font-medium text-amber-700">Message</label>
                <textarea 
                  id="message" 
                  rows={4} 
                  className="mt-1 block w-full border border-amber-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-amber-500 focus:border-amber-500"
                ></textarea>
              </div>
              <button 
                type="submit" 
                className="bg-amber-600 text-white px-4 py-2 rounded hover:bg-amber-700 transition"
              >
                Send Message
              </button>
            </form>
          </div>
        </div>
      </main>
    </Layout>
  );
}
