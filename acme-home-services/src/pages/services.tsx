import Layout from '@/components/Layout';

export default function Services() {
  return (
    <Layout 
      title="Our Services - Acme Home Services"
      description="Plumbing and HVAC services we offer"
    >
      <main className="container mx-auto px-4 py-8">
        <h1 className="text-4xl font-bold text-amber-800 mb-6">Our Services</h1>
        
        <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
          <div className="bg-white p-6 rounded-lg shadow-md">
            <h2 className="text-2xl font-semibold text-amber-800 mb-4">Plumbing Services</h2>
            <ul className="list-disc pl-5 text-amber-700 space-y-2">
              <li>Emergency leak repairs</li>
              <li>Pipe replacement and repair</li>
              <li>Water heater installation</li>
              <li>Drain cleaning</li>
              <li>Fixture installation</li>
            </ul>
          </div>
          
          <div className="bg-white p-6 rounded-lg shadow-md">
            <h2 className="text-2xl font-semibold text-amber-800 mb-4">HVAC Services</h2>
            <ul className="list-disc pl-5 text-amber-700 space-y-2">
              <li>Furnace repair and installation</li>
              <li>AC unit maintenance</li>
              <li>Thermostat installation</li>
              <li>Duct cleaning</li>
              <li>24/7 emergency service</li>
            </ul>
          </div>
        </div>
      </main>
    </Layout>
  );
}
