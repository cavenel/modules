process ELPREP_MERGE {
    tag "$meta.id"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/elprep:5.1.3--he881be0_1':
        'biocontainers/elprep:5.1.3--he881be0_1' }"

    input:
    tuple val(meta), path(bam)

    output:
    tuple val(meta), path("output/**.{bam,sam}")    , emit: bam
    path "versions.yml"                             , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args        = task.ext.args ?: ''
    def prefix      = task.ext.prefix ?: "${meta.id}"
    def suffix      = args.contains("--output-type sam") ? "sam" : "bam"
    def single_end  = meta.single_end ? " --single-end" : ""

    """
    # create directory and move all input so elprep can find and merge them before splitting
    mkdir input
    mv ${bam} input/

    elprep merge \\
        input/ \\
        output/${prefix}.${suffix} \\
        $args \\
        ${single_end} \\
        --log-path . \\
        --nr-of-threads $task.cpus

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        elprep: \$(elprep 2>&1 | head -n2 | tail -n1 |sed 's/^.*version //;s/ compiled.*\$//')
    END_VERSIONS
    """

    stub:
    def prefix      = task.ext.prefix ?: "${meta.id}"
    def suffix      = args.contains("--output-type sam") ? "sam" : "bam"
    """
    mkdir -p output
    touch output/${prefix}.${suffix}
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        elprep: \$(elprep 2>&1 | head -n2 | tail -n1 |sed 's/^.*version //;s/ compiled.*\$//')
    END_VERSIONS
    """
}
