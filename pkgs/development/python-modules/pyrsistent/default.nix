{ stdenv
, buildPythonPackage
, fetchPypi
, six
, pytest
, hypothesis
}:

buildPythonPackage rec {
  pname = "pyrsistent";
  version = "0.14.6";

  src = fetchPypi {
    inherit pname version;
    sha256 = "5a31f6b093da3401fefdeb53a0980e3145bb9d2bf852b579cc7b39c7f0016c87";
  };

  propagatedBuildInputs = [ six ];
  buildInputs = [ pytest hypothesis ];

  checkPhase = ''
    py.test
  '';

  meta = with stdenv.lib; {
    homepage = https://github.com/tobgu/pyrsistent/;
    description = "Persistent/Functional/Immutable data structures";
    license = licenses.mit;
    maintainers = with maintainers; [ desiderius ];
  };

}
