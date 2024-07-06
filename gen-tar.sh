COMMIT=$(git rev-parse --short HEAD); git archive --format=tar --prefix=rf-certutil-$COMMIT/ $COMMIT | gzip > ../rf-certutil-$COMMIT.tar.gz; echo ../rf-certutil-$COMMIT.tar.gz
