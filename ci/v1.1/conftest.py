"""
Configure for pytest.

Parses the command-line arguments, reads the environment variables,
and then creates the two DynamoDB tables before executing the tests.

The tests all assume that these tables have already been created.

Reusing the tables for all tests makes them faster at the expense
of potential loss of accuracy. A test may leave junk in a table
that confounds a later test, either by making a failed test
succeed or making a successful test fail.
"""

# Standard libraries
import os

# Installed packages
import pytest

# Local modules
import create_tables


def pytest_addoption(parser):
    """
    Add command-line options to the pytest application.

    Although these "options" are prefixed by '--', they
    are all required for the test suite to run.
    """
    parser.addoption(
        '--user_address',
        dest='user_address',
        help="DNS name or IP address of user service."
        )
    parser.addoption(
        '--user_port',
        type=int,
        help="Port number of user service."
       )
    parser.addoption(
        '--music_address',
        help="DNS name or IP address of music service."
        )
    parser.addoption(
        '--music_port',
        type=int,
        help="Port number of music service."
        )
    parser.addoption(
        '--table_suffix',
        help="Suffix to add to table names (not including leading "
             "'-').  If suffix is 'scp756-2022', the music table "
             "will be 'Music-scp756-2022'."
        )


@pytest.fixture
def user_address(request):
    return request.config.getoption('--user_address')


@pytest.fixture
def user_port(request):
    return request.config.getoption('--user_port')


@pytest.fixture
def music_address(request):
    return request.config.getoption('--music_address')


@pytest.fixture
def music_port(request):
    return request.config.getoption('--music_port')


@pytest.fixture
def table_suffix(request):
    return request.config.getoption('--table_suffix')


@pytest.fixture
def user_url(request, user_address, user_port):
    return "http://{}:{}/api/v1/user/".format(
        user_address, user_port)


@pytest.fixture
def music_url(request, music_address, music_port):
    return "http://{}:{}/api/v1/music/".format(
        music_address, music_port)


@pytest.fixture
def auth(request):
    """Return a dummy authorization header.

    Parameters
    ----------
    request: standard first argument to a pytest fixture.

    Notes
    -----
    The services check only that we pass an authorization,
    not whether it's valid.
    """
    return 'Bearer A'


def get_env_vars(args):
    """Augment the arguments with environment variable values.

    Parameters
    ----------
    args: namespace
        The command-line argument values.

    Environment variables
    ---------------------
    AWS_REGION, AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY,
        SVC_LOADER_TOKEN, DYNAMODB_URL: string
        Environment variables specifying these AWS access parameters.

    Modifies
    -------
    args
        The args namespace augmented with the following names:
        dynamodb_region, access_key_id, secret_access_key, loader_token,
        dynamodb_url

        These names contain the string values passed in the corresponding
        environment variables.

    Returns
    -------
    Nothing
    """
    # These are required to be present
    args.dynamodb_region = os.getenv('AWS_REGION')
    args.access_key_id = os.getenv('AWS_ACCESS_KEY_ID')
    args.secret_access_key = os.getenv('AWS_SECRET_ACCESS_KEY')
    args.loader_token = os.getenv('SVC_LOADER_TOKEN')
    args.dynamodb_url = os.getenv('DYNAMODB_URL')


def setup(args):
    """Create the DynamoDB tables.

    Parameters
    ----------
    args: namespace
        The arguments specifying the tables. Uses dynamodb_url,
        dynamodb_region, access_key_id, secret_access_key, table_suffix.
    """
    create_tables.create_tables(
        args.dynamodb_url,
        args.dynamodb_region,
        args.access_key_id,
        args.secret_access_key,
        'Music-' + args.table_suffix,
        'User-' + args.table_suffix
    )


def pytest_configure(config):
    """Configure the environment for the test suite.

    Parses the command line arguments, reads the environment variables,
    and creates the two DyndamoDB tables.
    """
    get_env_vars(config.option)
    setup(config.option)
