import React from 'react';
import PropTypes from 'prop-types';

const MovieDetails = ({ movie }) => {
  return (
    <li>
      <span>{movie.title}</span> (ID: {movie.id})
    </li>
  );
};

MovieDetails.propTypes = {
  movie: PropTypes.shape({
    id: PropTypes.string.isRequired,
    title: PropTypes.string.isRequired
  }).isRequired
};

export default MovieDetails;
