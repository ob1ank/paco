#define CPU_MIRROR_SESSION_ID 250

header_type ethernet_t {
    fields {
        dstAddr : 48;
        srcAddr : 48;
        etherType : 16;
    }
}

header ethernet_t ethernet;

header_type ipv4_t {
    fields {
        version : 4;
        ihl : 4;
        diffserv : 8;
        totalLen : 16;
        identification : 16;
        flags : 3;
        fragOffset : 13;
        ttl : 8;
        protocol : 8;
        hdrChecksum : 16;
        srcAddr : 32;
        dstAddr: 32;
    }
}

header ipv4_t ipv4;

header_type cpu_header_t {
    fields {
        device: 8;
    }
}

header cpu_header_t cpu_header;

parser start {
    /*
    return parse_ethernet;
    */
    return select(current(0,128)) {
        0 : parse_cpu_header;
        default : parse_ethernet;
    }
}

parser parse_cpu_header {
    extract(cpu_header);
    return ingress;
}

parser parse_ethernet {
    extract(ethernet);
    return parse_ipv4;
}

parser parse_ipv4 {
    extract(ipv4);
    return ingress;
}

action next_hop(output_port){
    modify_field(standard_metadata.egress_spec, output_port);
}

field_list copy2cpu_fields {
    standard_metadata;
}

action copy2cpu() {
    clone_ingress_pkt_to_egress(CPU_MIRROR_SESSION_ID, copy2cpu_fields);
}

action forward() {
    /*
    modify_field(standard_metadata.egress_spec, standard_metadata.egress_spec);
    drop();
    */
}

action do_cpu_encap(device_id) {
    add_header(cpu_header);
    modify_field(cpu_header.device, device_id);
}

table deal_ipv4 {
    reads {
        ipv4.srcAddr : exact;
        ipv4.dstAddr : exact;
    }
    actions {
        next_hop;
        copy2cpu;
    }
}

table redirect {
    reads {
        standard_metadata.instance_type : exact;
    }
    actions {
        forward;
        do_cpu_encap;
    }
}
       
control ingress {
    apply(deal_ipv4);
}

control egress {
    apply(redirect);
}
