import React, { useState, useEffect } from 'react';
import MovieDetails from './MovieDetails';

const MovieList = () => {
  const [movies, setMovies] = useState([]);
  const [error, setError] = useState(null);

  const apiUrl = process.env.REACT_APP_MOVIE_API_URL || 'http://localhost:5000';

  useEffect(() => {
    fetch(`${apiUrl}/movies/`)
      .then((res) => {
        if (!res.ok) {
          throw new Error('Failed to fetch movies');
        }
        return res.json();
      })
      .then((data) => {
        setMovies(data.movies || []);
      })
      .catch((err) => {
        setError(err.message);
      });
  }, [apiUrl]);

  if (error) {
    return <p>Error loading movies: {error}</p>;
  }

  return (
    <ul>
      {movies.map((movie) => (
        <MovieDetails key={movie.id} movie={movie} />
      ))}
    </ul>
  );
};

export default MovieList;
