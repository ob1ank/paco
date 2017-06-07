header_type paco_head_t {
    fields {
        pathlet_ids: 32;
        ori_etherType: 16;
    }
}

header paco_head_t paco_head;

header_type ingress_metadata_t{
    fields {
        pacoEnable : 1;
        srcAddr	: 32;
        dstAddr	: 32;
    }
}

metadata ingress_metadata_t route_metadata;

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
    return parse_route_metadata;
}

#define ETHERTYPE_IPV4 0x0800
#define ETHERTYPE_TAG 0x0037

parser parse_route_metadata {
    extract(ethernet);
    return select(route_metadata.pacoEnable){
        0x0 : parse_ethernet;
        0x1 : ingress;
    }
}

parser parse_ethernet{
    return select(ethernet.etherType){
        0x0800: parse_ipv4;
        0x0037: parse_paco;
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

field_list route_resubmit_list{
	route_metadata.pacoEnable;
	route_metadata.srcAddr;
	route_metadata.dstAddr;
}

action ipv42paco(src, dst) {
    modify_field(route_metadata.pacoEnable, 1);
    modify_field(route_metadata.srcAddr, src);
    modify_field(route_metadata.dstAddr, dst);
    resubmit(route_resubmit_list);
}

action next_hop(output_port) {
    modify_field(standard_metadata.egress_spec, output_port);
}

action add_paco(id, output_port){
    add_header(paco_head);
    modify_field(paco_head.ori_etherType, ethernet.etherType);
    modify_field(ethernet.etherType, 0x0037);
    modify_field(paco_head.pathlet_ids, id);
    modify_field(route_metadata.pacoEnable, 0);
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

table forward_ipv4 {
    reads {
        ipv4.srcAddr : exact;
        ipv4.dstAddr : exact;
    }
    actions {
        ipv42paco;
        next_hop;
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
    }
}

table enable_paco{
    reads {
        route_metadata.srcAddr : exact;
        route_metadata.dstAddr : exact;
    }
    actions{
        add_paco;
    }
}

control ingress {
    if (ethernet.etherType == 0x0037){
        apply(forward_paco);
    }
    if (ethernet.etherType == 0x0800 and route_metadata.pacoEnable == 0){
        apply(forward_ipv4);
    }
    if (route_metadata.pacoEnable == 1){
        apply(enable_paco);
    }
}
