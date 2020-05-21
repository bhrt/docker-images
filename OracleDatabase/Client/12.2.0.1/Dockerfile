FROM oraclelinux:7-slim as base

# Labels
# ------

LABEL "provider"="PSI AG"                                               \
      "maintainer"="lwozniak@psi.pl"                                    \
      "issues"="https://jira-bld-log.psi.de/browse/PSIWMS-5639"         \
      "todo"="optimize client components for docker installation for image size reduction"

# Environment variables required for this build (do NOT change)
# -------------------------------------------------------------
ENV ORACLE_BASE=/u01/app/oracle \
    ORACLE_HOME=/u01/app/oracle/product/12.2.0.1/client_1 \
    ORACLE_INV=/u01/app/oraInventory \
    INSTALL_DIR=/u01/install \
    INSTALL_FILE_1="linuxx64_12201_client.zip" \
    INSTALL_RSP="client_install.rsp" \
    SETUP_LINUX_FILE="setupLinuxEnv.sh" \
    CHECK_SPACE_FILE="checkSpace.sh" \
    TMP=/tmp    \
    TMPDIR=/tmp \
    INSTALL_DB_BINARIES_FILE="installDBBinaries.sh" \
    RUN_FILE="sqlplus -v"

# Use second ENV so that variable get substituted
ENV PATH=$ORACLE_HOME/bin:/usr/sbin:$PATH \
    LD_LIBRARY_PATH=$ORACLE_HOME/lib:/usr/lib \
    CLASSPATH=$ORACLE_HOME/jlib:$ORACLE_HOME/rdbms/jlib

# Copy files needed during both installation and runtime
# -------------
COPY $SETUP_LINUX_FILE $CHECK_SPACE_FILE $INSTALL_DIR/

RUN chmod ug+x $INSTALL_DIR/*.sh && \
    sync && \
    $INSTALL_DIR/$CHECK_SPACE_FILE && \
    $INSTALL_DIR/$SETUP_LINUX_FILE && \
    rm -rf $INSTALL_DIR

#############################################
# -------------------------------------------
# Start new stage for installing the database
# -------------------------------------------
#############################################

FROM base AS builder

# Install unzip for unzip operation
RUN yum -y install unzip && rm -rf /var/cache/yum

# Copy DB install file
COPY --chown=oracle:dba $INSTALL_FILE_1 $INSTALL_RSP $INSTALL_DB_BINARIES_FILE $INSTALL_DIR/

RUN usermod -a -G oinstall oracle

# Install DB software binaries
USER oracle
RUN chmod ug+x $INSTALL_DIR/*.sh && \
    sync && \
    $INSTALL_DIR/$INSTALL_DB_BINARIES_FILE



#############################################
# -------------------------------------------
# Start new layer for database runtime
# -------------------------------------------
#############################################

FROM base

USER oracle
COPY --chown=oracle:dba --from=builder $ORACLE_BASE $ORACLE_BASE

USER root
RUN $ORACLE_HOME/root.sh

USER oracle
WORKDIR /home/oracle

# Define default command to start Oracle Database. 
CMD exec $RUN_FILE
