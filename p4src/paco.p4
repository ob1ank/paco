header_type paco_head_t {
    fields {
        pathlet_ids: 32;
        ori_etherType: 16;
    }
}

header paco_head_t paco_head;

header_type cpu_header_t {
    fields {
        device: 8;
    }
}

header cpu_header_t cpu_header;

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

parser start {
    return select(current(0,128)) {
        0 : parse_cpu_header;
        default : parse_ethernet;
    }
}

parser parse_cpu_header {
    extract(cpu_header);
    return ingress;
}

#define ETHERTYPE_IPV4 0x0800
#define ETHERTYPE_PACO 0x0037
#define CPU_MIRROR_SESSION_ID 250

parser parse_ethernet{
    extract(ethernet);
    return select(ethernet.etherType){
        ETHERTYPE_IPV4: parse_ipv4;
        ETHERTYPE_PACO: parse_paco;
    }
}

parser parse_ipv4 {
    extract(ipv4);
    return ingress;
}

parser parse_paco {
    extract(paco_head);
    return ingress;
}

action next_hop(output_port) {
    modify_field(standard_metadata.egress_spec, output_port);
}

action ipv42paco(ids, output_port){
    add_header(paco_head);
    modify_field(paco_head.ori_etherType, ethernet.etherType);
    modify_field(ethernet.etherType, 0x0037);
    modify_field(paco_head.pathlet_ids, ids);
    modify_field(standard_metadata.egress_spec, output_port);	
}

action pathlet_mid_forward(output_port) {
    modify_field(standard_metadata.egress_spec, output_port);
}

action pathlet_NULL_forward(output_port) {
    modify_field(standard_metadata.egress_spec, output_port);
    modify_field(ethernet.etherType, paco_head.ori_etherType);
    remove_header(paco_head);
}

action pathlet_tail_forward(output_port) {
    modify_field(standard_metadata.egress_spec, output_port);
    shift_left(paco_head.pathlet_ids, paco_head.pathlet_ids, 8);
}

action pathlet_multi_forward(number, new_ids, output_port){
    bit_and(paco_head.pathlet_ids, paco_head.pathlet_ids, 0x00FFFFFF);
    shift_right(paco_head.pathlet_ids, paco_head.pathlet_ids, 8 * number);
    bit_or(paco_head.pathlet_ids, paco_head.pathlet_ids, new_ids);
    modify_field(standard_metadata.egress_spec, output_port);
}

field_list copy2cpu_fields {
    standard_metadata;
}

action copy2cpu() {
    clone_ingress_pkt_to_egress(CPU_MIRROR_SESSION_ID, copy2cpu_fields);
}

action forward() {
    modify_field(standard_metadata.egress_spec, standard_metadata.egress_spec);
    /*
    drop();
    */
}

action do_cpu_encap(device_id) {
    add_header(cpu_header);
    modify_field(cpu_header.device, device_id);
}

table forward_ipv4 {
    reads {
        ipv4.srcAddr : exact;
        ipv4.dstAddr : exact;
    }
    actions {
        ipv42paco;
        next_hop;
        copy2cpu;
    }
}

table forward_paco{
    reads {
        paco_head.pathlet_ids : lpm;
    }
    actions{
        pathlet_mid_forward;
        pathlet_tail_forward;
        pathlet_NULL_forward;
        pathlet_multi_forward;
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
    if (ethernet.etherType == ETHERTYPE_PACO){
        apply(forward_paco);
    }
    if (ethernet.etherType == ETHERTYPE_IPV4){
        apply(forward_ipv4);
    }
}

control egress {
    apply(redirect);
}
