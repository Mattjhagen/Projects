import Layout from '@/components/Layout';

export default function About() {
  return (
    <Layout 
      title="About Acme Home Services - Chicago Plumbing & HVAC"
      description="Learn about our team and values"
    >
      <main className="container mx-auto px-4 py-8">
        <h1 className="text-4xl font-bold text-amber-800 mb-6">About Acme Home Services</h1>
        
        <div className="bg-white p-6 rounded-lg shadow-md mb-8">
          <h2 className="text-2xl font-semibold text-amber-800 mb-4">Our Story</h2>
          <p className="text-amber-700 mb-4">
            Founded in 1995 by John Smith, Acme Home Services has been serving the Chicago area with 
            reliable plumbing and HVAC services for over 25 years.
          </p>
          <p className="text-amber-700">
            What started as a one-man operation has grown into a team of 15 licensed professionals 
            dedicated to quality work and customer satisfaction.
          </p>
        </div>
        
        <div className="bg-white p-6 rounded-lg shadow-md">
          <h2 className="text-2xl font-semibold text-amber-800 mb-4">Our Values</h2>
          <ul className="list-disc pl-5 text-amber-700 space-y-2">
            <li>Honesty and transparency in all our work</li>
            <li>Quality craftsmanship with attention to detail</li>
            <li>Respect for your home and time</li>
            <li>Continuous learning to stay current with industry standards</li>
          </ul>
        </div>
      </main>
    </Layout>
  );
}
