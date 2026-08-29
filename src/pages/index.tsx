import React from 'react'
import Head from 'next/head'
import Link from 'next/link'

export default function Home() {
  return (
    <>
      <Head>
        <title>Acme Home Services | Premier Plumbing, Heating & AC Repair in Chicago</title>
        <meta name="description" content="24/7 Emergency Plumbing, Heating, Air Conditioning & Electrical Repair for Chicago Homeowners. Licensed, Insured & Local." />
      </Head>

      <header style={{ background: '#0F172A', borderBottom: '1px solid #1E293B', padding: '1rem 2rem', display: 'flex', justifyContent: 'space-between', alignItems: 'center', color: '#fff' }}>
        <div style={{ fontSize: '1.5rem', fontWeight: 800, color: '#38BDF8' }}>🛠️ Acme Home Services</div>
        <nav style={{ display: 'flex', gap: '1.5rem', fontSize: '0.9375rem', fontWeight: 600 }}>
          <Link href="/" style={{ color: '#38BDF8', textDecoration: 'none' }}>Home</Link>
          <Link href="/services" style={{ color: '#94A3B8', textDecoration: 'none' }}>Services</Link>
          <Link href="/about" style={{ color: '#94A3B8', textDecoration: 'none' }}>About</Link>
          <Link href="/pricing" style={{ color: '#94A3B8', textDecoration: 'none' }}>Pricing</Link>
          <Link href="/contact" style={{ color: '#94A3B8', textDecoration: 'none' }}>Contact</Link>
        </nav>
        <a href="tel:3125550199" style={{ background: '#0284C7', color: '#fff', padding: '0.5rem 1.25rem', borderRadius: '6px', fontWeight: 700, textDecoration: 'none' }}>📞 (312) 555-0199</a>
      </header>

      <main style={{ fontFamily: 'system-ui, sans-serif', background: '#020617', color: '#F8FAFC', minHeight: '80vh' }}>
        <div style={{ background: '#0284C7', color: '#fff', textAlign: 'center', padding: '0.625rem', fontWeight: 700, fontSize: '0.875rem' }}>
          🚨 24/7 Emergency Service Available Across Chicago & Suburbs — Fast Response Guaranteed!
        </div>

        <section style={{ maxWidth: '1100px', margin: '0 auto', padding: '4rem 1.5rem', textAlign: 'center' }}>
          <h1 style={{ fontSize: '3rem', fontWeight: 900, marginBottom: '1rem', lineHeight: 1.2 }}>
            Chicago&apos;s Trusted <span style={{ color: '#38BDF8' }}>Plumbing, HVAC & Electrical</span> Experts
          </h1>
          <p style={{ fontSize: '1.25rem', color: '#94A3B8', maxWidth: '700px', margin: '0 auto 2rem' }}>
            Fast, reliable, and upfront flat-rate pricing. Over 15 years keeping Chicago homes warm, cool, and running smoothly.
          </p>
          <div style={{ display: 'flex', gap: '1rem', justifyContent: 'center' }}>
            <Link href="/contact" style={{ background: '#38BDF8', color: '#0F172A', padding: '0.875rem 2rem', borderRadius: '8px', fontWeight: 800, textDecoration: 'none', fontSize: '1rem' }}>Request Free Quote →</Link>
            <Link href="/services" style={{ background: '#1E293B', color: '#fff', padding: '0.875rem 2rem', borderRadius: '8px', fontWeight: 700, textDecoration: 'none', fontSize: '1rem' }}>View All Services</Link>
          </div>
        </section>

        <section style={{ maxWidth: '1100px', margin: '0 auto', padding: '2rem 1.5rem 4rem' }}>
          <h2 style={{ fontSize: '2rem', fontWeight: 800, textAlign: 'center', marginBottom: '2.5rem' }}>Our Core Home Services</h2>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(280px, 1fr))', gap: '1.5rem' }}>
            <div style={{ background: '#0F172A', border: '1px solid #1E293B', borderRadius: '12px', padding: '1.75rem' }}>
              <div style={{ fontSize: '2.5rem', marginBottom: '0.5rem' }}>🚰</div>
              <h3 style={{ fontSize: '1.25rem', fontWeight: 700, marginBottom: '0.5rem' }}>Plumbing & Drain Repair</h3>
              <p style={{ color: '#94A3B8', fontSize: '0.875rem', lineHeight: 1.6 }}>Clogged drains, water heater installs, pipe repair, sewer line inspections, and leak detection.</p>
            </div>
            <div style={{ background: '#0F172A', border: '1px solid #1E293B', borderRadius: '12px', padding: '1.75rem' }}>
              <div style={{ fontSize: '2.5rem', marginBottom: '0.5rem' }}>🔥</div>
              <h3 style={{ fontSize: '1.25rem', fontWeight: 700, marginBottom: '0.5rem' }}>Heating & Furnace Service</h3>
              <p style={{ color: '#94A3B8', fontSize: '0.875rem', lineHeight: 1.6 }}>Furnace repair, boiler maintenance, heat pump installations, and winter tune-ups.</p>
            </div>
            <div style={{ background: '#0F172A', border: '1px solid #1E293B', borderRadius: '12px', padding: '1.75rem' }}>
              <div style={{ fontSize: '2.5rem', marginBottom: '0.5rem' }}>❄️</div>
              <h3 style={{ fontSize: '1.25rem', fontWeight: 700, marginBottom: '0.5rem' }}>Air Conditioning & Cooling</h3>
              <p style={{ color: '#94A3B8', fontSize: '0.875rem', lineHeight: 1.6 }}>AC repair, ductless mini-splits, central air installation, and seasonal refrigerant checks.</p>
            </div>
          </div>
        </section>
      </main>
    </>
  )
}
