import cockpit from "cockpit";
import React from "react";
import { log_cmd, bad_file_name } from "../tools.jsx";
import { RUVTable } from "./replTables.jsx";
import { ExportCLModal } from "./replModals.jsx";
import { DoubleConfirmModal } from "../notifications.jsx";
import PropTypes from "prop-types";
import {
    Button,
    Form,
    Grid,
    GridItem,
    noop,
} from "@patternfly/react-core";
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import {
    faSyncAlt
} from '@fortawesome/free-solid-svg-icons';
import '@fortawesome/fontawesome-svg-core/styles.css';

export class ReplRUV extends React.Component {
    constructor(props) {
        super(props);

        this.state = {
            errObj: {},
            rid: "",
            localRID: "",
            ldifLocation: "",
            saveOK: false,
            showConfirmCleanRUV: false,
            modalChecked: false,
            modalSpinning: false,
            showConfirmCLImport: false,
            showCLExport: false,
            defaultCL: true,
            debugCL: false,
            decodeCL: false,
            exportCSN: false,
            ldifFile: "/tmp/changelog.ldif",
        };
        this.showConfirmCleanRUV = this.showConfirmCleanRUV.bind(this);
        this.closeConfirmCleanRUV = this.closeConfirmCleanRUV.bind(this);
        this.showConfirmCLImport = this.showConfirmCLImport.bind(this);
        this.closeConfirmCLImport = this.closeConfirmCLImport.bind(this);
        this.showCLExport = this.showCLExport.bind(this);
        this.closeCLExport = this.closeCLExport.bind(this);
        this.showConfirmExport = this.showConfirmExport.bind(this);
        this.closeConfirmExport = this.closeConfirmExport.bind(this);
        this.handleLDIFChange = this.handleLDIFChange.bind(this);
        this.handleCLLDIFChange = this.handleCLLDIFChange.bind(this);
        this.handleRadioChange = this.handleRadioChange.bind(this);
        this.handleChange = this.handleChange.bind(this);
        this.cleanRUV = this.cleanRUV.bind(this);
        this.exportChangelog = this.exportChangelog.bind(this);
        this.importChangelog = this.importChangelog.bind(this);
    }

    showConfirmCleanRUV (rid) {
        this.setState({
            rid: rid,
            showConfirmCleanRUV: true,
            modalChecked: false,
            modalSpinning: false,
        });
    }

    closeConfirmCleanRUV () {
        this.setState({
            showConfirmCleanRUV: false,
            modalChecked: false,
            modalSpinning: false,
        });
    }

    showConfirmCLImport () {
        this.setState({
            showConfirmCLImport: true,
            modalChecked: false,
            modalSpinning: false,
        });
    }

    closeConfirmCLImport () {
        this.setState({
            showConfirmCLImport: false,
            modalChecked: false,
            modalSpinning: false,
        });
    }

    showCLExport () {
        this.setState({
            saveOK: true,
            showCLExport: true,
            decodeCL: false,
            defaultCL: true,
            debugCL: false,
            exportChangelog: false,
            ldifFile: "/tmp/changelog.ldif"
        });
    }

    closeCLExport () {
        this.setState({
            showCLExport: false,
        });
    }

    showConfirmExport () {
        this.setState({
            saveOK: false,
            showConfirmExport: true,
            ldifLocation: ""
        });
    }

    closeConfirmExport () {
        this.setState({
            showConfirmExport: false,
        });
    }

    handleRadioChange(_, e) {
        // Handle the changelog export options
        let defaultCL = false;
        let debugCL = false;
        if (e.target.id == "defaultCL") {
            defaultCL = true;
        } else if (e.target.id == "debugCL") {
            debugCL = true;
        }
        this.setState({
            defaultCL: defaultCL,
            debugCL: debugCL,
        });
    }

    cleanRUV () {
        // Enable/disable agmt
        let cmd = ['dsconf', '-j', 'ldapi://%2fvar%2frun%2fslapd-' + this.props.serverId + '.socket',
            'repl-tasks', 'cleanallruv', '--replica-id=' + this.state.rid,
            '--force-cleaning', '--suffix=' + this.props.suffix];

        log_cmd('cleanRUV', 'Clean the rid', cmd);
        cockpit
                .spawn(cmd, {superuser: true, "err": "message"})
                .done(content => {
                    this.props.reload(this.props.suffix);
                    this.props.addNotification(
                        'success',
                        'Successfully started CleanAllRUV task');
                    this.closeConfirmCleanRUV();
                })
                .fail(err => {
                    let errMsg = JSON.parse(err);
                    this.props.addNotification(
                        "error",
                        `Failed to start CleanAllRUV task - ${errMsg.desc}`
                    );
                    this.closeConfirmCleanRUV();
                });
    }

    handleLDIFChange (e) {
        let value = e.target.value;
        let saveOK = true;
        if (value == "" || bad_file_name(value)) {
            saveOK = false;
        }
        this.setState({
            [e.target.id]: value,
            saveOK: saveOK
        });
    }

    handleCLLDIFChange (e) {
        let value = e.target.value;
        let saveOK = true;
        if (value == "" || value.indexOf(' ') >= 0) {
            saveOK = false;
        }
        this.setState({
            [e.target.id]: value,
            saveOK: saveOK
        });
    }

    handleChange (e) {
        let value = e.target.type === 'checkbox' ? e.target.checked : e.target.value;
        this.setState({
            [e.target.id]: value,
        });
    }

    importChangelog () {
        // Do changelog import
        let cmd = [
            "dsconf", "-j", "ldapi://%2fvar%2frun%2fslapd-" + this.props.serverId + ".socket",
            "replication", "import-changelog", "default", "--replica-root", this.props.suffix
        ];

        this.setState({
            modalSpinning: true,
        });

        log_cmd("importChangelog", "Import relication changelog via LDIF", cmd);
        cockpit
                .spawn(cmd, { superuser: true, err: "message" })
                .done(content => {
                    this.props.addNotification(
                        "success",
                        `Changelog was successfully initialized`
                    );
                    this.setState({
                        showConfirmCLImport: false,
                        modalSpinning: false,
                    });
                })
                .fail(err => {
                    let errMsg = JSON.parse(err);
                    this.props.addNotification(
                        "error",
                        `Error importing changelog LDIF - ${errMsg.desc}`
                    );
                    this.setState({
                        showConfirmCLImport: false,
                        modalSpinning: false,
                    });
                });
    }

    exportChangelog () {
        // Do changelog export
        let cmd = [
            "dsconf", "-j", "ldapi://%2fvar%2frun%2fslapd-" + this.props.serverId + ".socket",
            "replication", "export-changelog"
        ];

        if (this.state.defaultCL) {
            cmd.push("default");
        } else {
            cmd.push("to-ldif");
            if (this.state.exportCSN) {
                cmd.push("--csn-only");
            }
            if (this.state.decodeCL) {
                cmd.push("--decode");
            }
            if (this.state.ldifFile) {
                cmd.push("--output-file=" + this.state.ldifFile);
            }
        }
        cmd.push("--replica-root=" + this.props.suffix);

        this.setState({
            exportSpinner: true,
        });

        log_cmd("exportChangelog", "Import relication changelog via LDIF", cmd);
        cockpit
                .spawn(cmd, { superuser: true, err: "message" })
                .done(content => {
                    this.props.addNotification(
                        "success",
                        `Changelog was successfully exported`
                    );
                    this.setState({
                        showCLExport: false,
                        exportSpinner: false,
                    });
                })
                .fail(err => {
                    let errMsg = JSON.parse(err);
                    this.props.addNotification(
                        "error",
                        `Error importing changelog LDIF - ${errMsg.desc}`
                    );
                    this.setState({
                        showCLExport: false,
                        exportSpinner: false,
                    });
                });
    }

    render() {
        // Strip out the local RUV and display it different then only allow
        // cleaning of remote rids
        let remote_rows = [];
        let localRID = "";
        let localURL = "";
        let localCSN = "";
        let localRawCSN = "";
        let localMinCSN = "";
        let localRawMinCSN = "";
        for (let row of this.props.rows) {
            if (row.rid == this.props.localRID) {
                localRID = row.rid;
                localURL = row.url;
                localCSN = row.maxcsn;
                localRawCSN = row.raw_maxcsn;
                localMinCSN = row.csn;
                localRawMinCSN = row.raw_csn;
            } else {
                remote_rows.push(row);
            }
        }
        let localRUV =
            <div className="ds-left-indent-md">
                <Grid className="ds-margin-top-med">
                    <GridItem className="ds-label" span={2}>
                        Replica ID
                    </GridItem>
                    <GridItem span={10}>
                        <b>{localRID}</b>
                    </GridItem>
                </Grid>
                <Grid>
                    <GridItem className="ds-label" span={2}>
                        LDAP URL
                    </GridItem>
                    <GridItem span={10}>
                        <b>{localURL}</b>
                    </GridItem>
                </Grid>
                <Grid>
                    <GridItem className="ds-label" span={2}>
                        Min CSN
                    </GridItem>
                    <GridItem span={10}>
                        <b>{localMinCSN}</b> ({localRawMinCSN})
                    </GridItem>
                </Grid>
                <Grid>
                    <GridItem className="ds-label" span={2}>
                        Max CSN
                    </GridItem>
                    <GridItem span={10}>
                        <b>{localCSN}</b> ({localRawCSN})
                    </GridItem>
                </Grid>
            </div>;

        if (localRID == "") {
            localRUV =
                <div className="ds-indent">
                    <i>
                        There is no local RUV, the database might not have been initialized yet.
                    </i>
                </div>;
        }

        return (
            <div className="ds-margin-top-xlg ds-indent">
                <h4>Local RUV <FontAwesomeIcon
                    size="lg"
                    className="ds-left-margin ds-refresh"
                    icon={faSyncAlt}
                    title="Refresh the RUV for this suffixs"
                    onClick={() => {
                        this.props.reload(this.props.suffix);
                    }}
                />
                </h4>
                {localRUV}
                <hr />
                <h4 className="ds-margin-top">Remote RUV's <FontAwesomeIcon
                    size="lg"
                    className="ds-left-margin ds-refresh"
                    icon={faSyncAlt}
                    title="Refresh the RUV for this suffixs"
                    onClick={() => {
                        this.props.reload(this.props.suffix);
                    }}
                />
                </h4>
                <div className="ds-left-indent-md ds-margin-top-lg">
                    <RUVTable
                        rows={remote_rows}
                        confirmDelete={this.showConfirmCleanRUV}
                    />
                </div>
                <hr />
<<<<<<< HEAD
=======
                <h4 className="ds-margin-top-xlg">Create Replica Initialization LDIF File</h4>
                <Form className="ds-margin-top-lg ds-left-indent-md" isHorizontal>
                    <Grid className="ds-margin-top-lg">
                        <GridItem span={3}>
                            <Button
                                variant="primary"
                                onClick={this.showConfirmExport}
                                title="See Database Tab -> Backups & LDIFs to manage the new LDIF"
                            >
                                Export Replica
                            </Button>
                        </GridItem>
                        <GridItem span={9}>
                            <p className="ds-margin-top">
                                Export this suffix with the replication metadata to an LDIF file for initializing another replica.
                            </p>
                        </GridItem>
                    </Grid>
                </Form>
                <hr />
>>>>>>> b83eb5a75 (Issue 4169 - Migrate Replication & Schema tabs to PF4)
                <h4 className="ds-margin-top-xlg">Replication Change Log Tasks</h4>
                <Form className="ds-margin-top-lg ds-left-indent-md" isHorizontal>
                    <Grid className="ds-margin-top-lg">
                        <GridItem
                            span={3}
                            title="Export the changelog to an LDIF file.  Typically used for changelog encryption purposes, or debugging."
                        >
                            <Button
                                variant="primary"
                                onClick={this.showCLExport}
                            >
                                Export Changelog
                            </Button>
                        </GridItem>
                        <GridItem span={9}>
                            <p className="ds-margin-top">
                                Export the replication changelog to a LDIF file.  Used for preparing to encrypt the changelog, or simply for debugging.
                            </p>
                        </GridItem>
                    </Grid>
                    <Grid className="ds-margin-top-lg">
                        <GridItem
                            span={3}
                            title="Initialize the changelog with an LDIF file for changelog encryption purposes."
                        >
                            <Button
                                variant="primary"
                                onClick={this.showConfirmCLImport}
                            >
                                Import Changelog
                            </Button>
                        </GridItem>
                        <GridItem span={9}>
                            <p className="ds-margin-top">
                                Initialize the replication changelog from an LDIF file.  Used to initialize the change log after encryption has been enabled.
                            </p>
                        </GridItem>
                    </Grid>
                </Form>
                <hr />
                <DoubleConfirmModal
                    showModal={this.state.showConfirmCleanRUV}
                    closeHandler={this.closeConfirmCleanRUV}
                    handleChange={this.handleChange}
                    actionHandler={this.cleanRUV}
                    spinning={this.state.modalSpinning}
                    item={"Replica ID " + this.state.rid}
                    checked={this.state.modalChecked}
                    mTitle="Remove RUV Element (CleanAllRUV)"
                    mMsg="Are you sure you want to attempt to clean this Replica ID from the suffix?"
                    mSpinningMsg="Starting cleaning task (CleanAllRUV) ..."
                    mBtnName="Remove RUV Element"
                />
                <DoubleConfirmModal
                    showModal={this.state.showConfirmCLImport}
                    closeHandler={this.closeConfirmCLImport}
                    handleChange={this.handleChange}
                    actionHandler={this.importChangelog}
                    spinning={this.state.modalSpinning}
                    item={"Replicated Suffix " + this.props.suffix}
                    checked={this.state.modalChecked}
                    mTitle="Initialize Replication Changelog From LDIF"
                    mMsg="Are you sure you want to attempt to initialize the changelog from LDIF?  This will reject all operations during during the initialization."
                    mSpinningMsg="Initialzing Replication Change Log ..."
                    mBtnName="Import Changelog LDIF"
                />
<<<<<<< HEAD
=======
                <ExportModal
                    showModal={this.state.showConfirmExport}
                    closeHandler={this.closeConfirmExport}
                    handleChange={this.handleLDIFChange}
                    saveHandler={this.doExport}
                    spinning={this.state.exportSpinner}
                    ldifLocation={this.state.ldifLocation}
                    ldifRows={this.props.ldifRows}
                    saveOK={this.state.saveOK}
                />
>>>>>>> b83eb5a75 (Issue 4169 - Migrate Replication & Schema tabs to PF4)
                <ExportCLModal
                    showModal={this.state.showCLExport}
                    closeHandler={this.closeCLExport}
                    handleChange={this.handleChange}
                    handleLDIFChange={this.handleCLLDIFChange}
                    handleRadioChange={this.handleRadioChange}
                    saveHandler={this.exportChangelog}
                    defaultCL={this.state.defaultCL}
                    debugCL={this.state.debugCL}
                    decodeCL={this.state.decodeCL}
                    exportCSN={this.state.exportCSN}
                    ldifFile={this.state.ldifFile}
                    spinning={this.state.exportSpinner}
                    saveOK={this.state.saveOK}
                />
            </div>
        );
    }
}

ReplRUV.propTypes = {
    suffix: PropTypes.string,
    serverId: PropTypes.string,
    rows: PropTypes.array,
    addNotification: PropTypes.func,
    localRID: PropTypes.string,
    reload: PropTypes.func,
    reloadLDIF: PropTypes.func,
};

ReplRUV.defaultProps = {
    serverId: "",
    suffix: "",
    rows: [],
    addNotification: noop,
    localRID: "",
    reload: noop,
    reloadLDIF: noop,
};
