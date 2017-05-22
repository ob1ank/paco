header_type tag_head_t {
    fields {
        tags: 32;
        ori_type: 16;
    }
}

header tag_head_t tag_head;

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

/*
header_type local_metadata_t {
    fields {
        is_tag : 1;
    }
} 

metadata local_metadata_t local_metadata;
*/

parser start {
    return parse_ethernet;
}

#define ETHERTYPE_IPV4 0x0800
#define ETHERTYPE_TAG 0x0037

parser parse_ethernet {
    extract(ethernet);
    /*
    return select(latest.etherType) {
        ETHERTYPE_IPV4 : parse_ipv4;
        ETHERTYPE_TAG : parse_tag;
    }
    */
    return parse_ipv4;
}

parser parse_ipv4 {
    extract(ipv4);
    return select(ethernet.etherType){
    ETHERTYPE_IPV4 : ingress;
    ETHERTYPE_TAG : parse_tag;
    }
}

parser parse_tag {
    extract(tag_head);
    return ingress;
}

action ipv42tag(tags, output_port) {
    add_header(tag_head);
    modify_field(tag_head.ori_type, ethernet.etherType);
    modify_field(ethernet.etherType, 0x0037);
    modify_field(tag_head.tags, tags);
    modify_field(standard_metadata.egress_spec, output_port);
}

action tag_mid_action(output_port) {
    modify_field(standard_metadata.egress_spec, output_port);
}

action tag0_mid_action(output_port) {
    modify_field(standard_metadata.egress_spec, output_port);
    modify_field(ethernet.etherType, tag_head.ori_type);
    remove_header(tag_head);
}

action tag_tail_action(output_port) {
    modify_field(standard_metadata.egress_spec, output_port);
    shift_left(tag_head.tags, tag_head.tags, 8);
}

action multi_tag(number, new_tag, output_port){
    bit_and(tag_head.tags, tag_head.tags, 0x00FFFFFF);
    shift_right(tag_head.tags, tag_head.tags, 8 * number);
    bit_or(tag_head.tags, tag_head.tags, new_tag);
    modify_field(standard_metadata.egress_spec, output_port);
}

table deal_ipv4 {
    reads {
        ipv4.srcAddr : exact;
        ipv4.dstAddr : exact;
    }
    actions {
        ipv42tag;
    }
}
        
table tag0 {
    reads {
        tag_head.tags : lpm;
    }
    actions {
        tag0_mid_action;
    }
}

table deal_tag{
    reads {
        tag_head.tags : lpm;
    }
    actions{
        tag_mid_action;
        tag_tail_action;
        multi_tag;
    }
}

control ingress {
    if (ethernet.etherType == ETHERTYPE_TAG){
        if (tag_head.tags != 0x0){
            apply(deal_tag);
        }
        if (tag_head.tags == 0x0) {
            apply(tag0);
        }
    }
    if (ethernet.etherType != ETHERTYPE_TAG){
        apply(deal_ipv4);
    }
}
