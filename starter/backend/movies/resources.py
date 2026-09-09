# Movie catalog data resource model
MOVIES_DATABASE = [
    {
        'id': '123',
        'title': 'Top Gun: Maverick'
    },
    {
        'id': '456',
        'title': 'Sonic the Hedgehog'
    },
    {
        'id': '789',
        'title': 'A Quiet Place'
    }
]
# Function to retrieve full list of movie catalog items maintained in memory for the movie picture application tasks.

def get_all_movies():
    return MOVIES_DATABASE
