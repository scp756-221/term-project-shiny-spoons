"""
Return a unique hex hash for use in testing.
"""

# Standard libraries
import hashlib


def _compute_hash(userid, ex_string):
    h = hashlib.sha256()
    h.update(userid.encode('UTF-8'))
    h.update(ex_string.encode('UTF-8'))
    return h.hexdigest()


def exercise_hash(ex_string):
    """
    Return a unique hex hash for this student and exercise.

    Parameters
    ----------
    ex_string: string
        A string identifying this exercise.

    Template variable
    -----------------
    ZZ--REG--ID: string
        A userid for the container registry (typically GHCR)
        used in this course.
        NOTE: The actual template variable name uses only single '-'
        characters.

    Returns
    -------
    string
        A unique hex string, generated from the two parameters.
    """
    return _compute_hash('ZZ-REG-ID', ex_string)
