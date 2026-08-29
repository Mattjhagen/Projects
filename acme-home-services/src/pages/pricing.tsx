import Layout from '@/components/Layout';

export default function Pricing() {
  return (
    <Layout 
      title="Pricing - Acme Home Services"
      description="Transparent pricing for our services"
    >
      <main className="container mx-auto px-4 py-8">
        <h1 className="text-4lx font-bold text-amber-800 mb-6">Service Pricing</h1>
        
        <div className="bg-white p-6 rounded-lg shadow-md mb-8">
          <h2 className="text-2xl font-semibold text-amber-800 mb-4">Standard Rates</h2>
          <p className="text-amber-700 mb-4">
            All prices include parts and labor. Emergency services include a $75 after-hours fee.
          </p>
          
          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-amber-200">
              <thead className="bg-amber-100">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-amber-800 uppercase tracking-wider">Service</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-amber-800 uppercase tracking-wider">Price Range</th>
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-amber-200">
                <tr>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-amber-700">Water heater installation</td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-amber-700">$800 - $1,200</td>
                </tr>
                <tr>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-amber-700">Furnace repair</td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-amber-700">$150 - $400</td>
                </tr>
                <tr>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-amber-700">Drain cleaning</td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-amber-700">$125 - $250</td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
        
        <div className="bg-white p-6 rounded-lg shadow-md">
          <h2 className="text-2xl font-semibold text-amber-800 mb-4">Free Estimates</h2>
          <p className="text-amber-700">
            Contact us for a free, no-obligation estimate on any service. We guarantee our work 
            with a 1-year warranty on all repairs and installations.
          </p>
        </div>
      </main>
    </Layout>
  );
}
