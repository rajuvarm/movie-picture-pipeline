import React from 'react';
import { render, screen, waitFor } from '@testing-library/react';
import '@testing-library/jest-dom';
import MovieList from '../MovieList';

const mockMovies = {
  movies: [
    { id: '123', title: 'Top Gun: Maverick' },
    { id: '456', title: 'Sonic the Hedgehog' },
    { id: '789', title: 'A Quiet Place' }
  ]
};

beforeEach(() => {
  global.fetch = jest.fn(() =>
    Promise.resolve({
      ok: true,
      json: () => Promise.resolve(mockMovies)
    })
  );
});

afterEach(() => {
  jest.restoreAllMocks();
});

test('renders movies list after API fetch', async () => {
  render(<MovieList />);
  await waitFor(() => {
    expect(screen.getByText('Top Gun: Maverick')).toBeInTheDocument();
    expect(screen.getByText('Sonic the Hedgehog')).toBeInTheDocument();
    expect(screen.getByText('A Quiet Place')).toBeInTheDocument();
  });
});

test('renders empty list when no movies returned', async () => {
  global.fetch = jest.fn(() =>
    Promise.resolve({
      ok: true,
      json: () => Promise.resolve({ movies: [] })
    })
  );
  render(<MovieList />);
  const listElement = screen.getByRole('list');
  expect(listElement).toBeInTheDocument();
  expect(listElement.children.length).toBe(0);
});
