import React from 'react';
import { render, screen } from '@testing-library/react';
import '@testing-library/jest-dom';
import App from '../../App';

const movieHeading = process.env.FAIL_TEST ? 'messed_up' : 'Movie List';

test('renders Movie List heading', () => {
  render(<App />);
  const linkElement = screen.getByText(movieHeading);
  expect(linkElement).toBeInTheDocument();
});
