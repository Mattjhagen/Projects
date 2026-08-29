import React from 'react'
import Head from 'next/head'
import Link from 'next/link'

export default function Services() {
  return (
    <>
      <Head><title>Services | Acme Home Services Chicago</title></Head>
      <header style={{ background: '#0F172A', borderBottom: '1px solid #1E293B', padding: '1rem 2rem', display: 'flex', justifyContent: 'space-between', alignItems: 'center', color: '#fff' }}>
        <div style={{ fontSize: '1.5rem', fontWeight: 800, color: '#38BDF8' }}>🛠️ Acme Home Services</div>
        <nav style={{ display: 'flex', gap: '1.5rem', fontSize: '0.9375rem', fontWeight: 600 }}>
          <Link href="/" style={{ color: '#94A3B8', textDecoration: 'none' }}>Home</Link>
          <Link href="/services" style={{ color: '#38BDF8', textDecoration: 'none' }}>Services</Link>
          <Link href="/about" style={{ color: '#94A3B8', textDecoration: 'none' }}>About</Link>
          <Link href="/pricing" style={{ color: '#94A3B8', textDecoration: 'none' }}>Pricing</Link>
          <Link href="/contact" style={{ color: '#94A3B8', textDecoration: 'none' }}>Contact</Link>
        </nav>
      </header>
      <main style={{ fontFamily: 'system-ui, sans-serif', background: '#020617', color: '#F8FAFC', minHeight: '80vh', padding: '4rem 2rem' }}>
        <div style={{ maxWidth: '900px', margin: '0 auto' }}>
          <h1 style={{ fontSize: '2.5rem', fontWeight: 900, marginBottom: '1rem', color: '#38BDF8' }}>Full Service Plumbing, HVAC & Electrical</h1>
          <p style={{ color: '#94A3B8', fontSize: '1.125rem', marginBottom: '3rem' }}>Licensed technicians bringing top-tier workmanship and transparent pricing to every job.</p>

          <div style={{ display: 'flex', flexDirection: 'column', gap: '2rem' }}>
            <div style={{ background: '#0F172A', border: '1px solid #1E293B', borderRadius: '12px', padding: '2rem' }}>
              <h2 style={{ fontSize: '1.5rem', fontWeight: 700, color: '#38BDF8', marginBottom: '0.5rem' }}>🚰 Plumbing Solutions</h2>
              <ul style={{ color: '#CBD5E1', lineHeight: 1.8 }}>
                <li>Drain cleaning & hydro-jetting</li>
                <li>Tankless & conventional water heater installation</li>
                <li>Sump pump installation & battery backup systems</li>
                <li>Gas line repair & replacement</li>
              </ul>
            </div>
            <div style={{ background: '#0F172A', border: '1px solid #1E293B', borderRadius: '12px', padding: '2rem' }}>
              <h2 style={{ fontSize: '1.5rem', fontWeight: 700, color: '#38BDF8', marginBottom: '0.5rem' }}>🔥 Heating & Cooling</h2>
              <ul style={{ color: '#CBD5E1', lineHeight: 1.8 }}>
                <li>High-efficiency furnace & boiler installation</li>
                <li>Emergency AC & furnace repair</li>
                <li>Indoor air quality & duct filtration</li>
                <li>Smart thermostat setup (Nest, Ecobee)</li>
              </ul>
            </div>
          </div>
        </div>
      </main>
    </>
  )
}
