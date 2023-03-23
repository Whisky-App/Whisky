#
# Author: Zoltan Varga (vargaz@gmail.com)
# License: MIT/X11
#

#
# This is a mono support mode for lldb
#

# Comments about the lldb python api:
# - there are no accessors, i.e. valobj["name"]
# - http://lldb.llvm.org/python_reference/index.html seems to be outdated
# - there is no autoload support, i.e. can't load this file automatically
#   when 'mono' is the debugger target.

import lldb

# FIXME: Generate enums from runtime enums
MONO_TYPE_END        = 0x00
MONO_TYPE_VOID       = 0x01
MONO_TYPE_BOOLEAN    = 0x02
MONO_TYPE_CHAR       = 0x03
MONO_TYPE_I1         = 0x04
MONO_TYPE_U1         = 0x05
MONO_TYPE_I2         = 0x06
MONO_TYPE_U2         = 0x07
MONO_TYPE_I4         = 0x08
MONO_TYPE_U4         = 0x09
MONO_TYPE_I8         = 0x0a
MONO_TYPE_U8         = 0x0b
MONO_TYPE_R4         = 0x0c
MONO_TYPE_R8         = 0x0d
MONO_TYPE_STRING     = 0x0e
MONO_TYPE_PTR        = 0x0f
MONO_TYPE_BYREF      = 0x10
MONO_TYPE_VALUETYPE  = 0x11
MONO_TYPE_CLASS      = 0x12
MONO_TYPE_VAR	     = 0x13
MONO_TYPE_ARRAY      = 0x14
MONO_TYPE_GENERICINST= 0x15
MONO_TYPE_TYPEDBYREF = 0x16
MONO_TYPE_I          = 0x18
MONO_TYPE_U          = 0x19
MONO_TYPE_FNPTR      = 0x1b
MONO_TYPE_OBJECT     = 0x1c
MONO_TYPE_SZARRAY    = 0x1d
MONO_TYPE_MVAR	     = 0x1e

primitive_type_names = {
    MONO_TYPE_BOOLEAN : "bool",
    MONO_TYPE_CHAR : "char",
    MONO_TYPE_I1 : "sbyte",
    MONO_TYPE_U1 : "byte",
    MONO_TYPE_I2 : "short",
    MONO_TYPE_U2 : "ushort",
    MONO_TYPE_I4 : "int",
    MONO_TYPE_U4 : "uint",
    MONO_TYPE_I8 : "long",
    MONO_TYPE_U8 : "ulong",
    MONO_TYPE_R4 : "float",
    MONO_TYPE_R8 : "double",
    MONO_TYPE_STRING : "string"
    }

#
# Helper functions for working with the lldb python api
#

def member(val, member_name):
    return val.GetChildMemberWithName (member_name)

def string_member(val, member_name):
    return val.GetChildMemberWithName (member_name).GetSummary ()[1:-1]

def isnull(val):
    return val.deref.addr.GetOffset () == 0

def stringify_class_name(ns, name):
    if ns == "System":
        if name == "Byte":
            return "byte"
        if name == "String":
            return "string"
    if ns == "":
        return name
    else:
        return "{0}.{1}".format (ns, name)

#
# Pretty printers for mono runtime types
#

def stringify_type (type):
    "Print a MonoType structure"
    ttype = member(type, "type").GetValueAsUnsigned()
    if primitive_type_names.has_key (ttype):
        return primitive_type_names [ttype]
    else:
        return "<MonoTypeEnum 0x{0:x}>".format (ttype)

def stringify_ginst (ginst):
    "Print a MonoGenericInst structure"
    len = int(member(ginst, "type_argc").GetValue())
    argv = member(ginst, "type_argv")
    res=""
    for i in range(len):
        t = argv.GetChildAtIndex(i, False, True)
        if i > 0:
            res += ", "
        res += stringify_type(t)
    return res

def print_type(valobj, internal_dict):
    type = valobj
    if isnull (type):
        return ""
    return stringify_type (type)

def print_class (valobj, internal_dict):
    klass = valobj
    if isnull (klass):
        return ""
    aname = member (member (member (klass, "image"), "assembly"), "aname")
    basename = "[{0}]{1}".format (string_member (aname, "name"), (stringify_class_name (string_member (klass, "name_space"), string_member (klass, "name"))))
    gclass = member (klass, "generic_class")
    if not isnull (gclass):
        ginst = member (member (gclass, "context"), "class_inst")
        return "{0}<{1}>".format (basename, stringify_ginst (ginst))
    return basename

def print_method (valobj, internal_dict):
    method = valobj
    if isnull (method):
        return ""
    klass = member (method, "klass")
    return "{0}:{1}()".format (print_class (klass, None), string_member (valobj, "name"))

def print_domain(valobj, internal_dict):
    domain = valobj
    if isnull (domain):
        return ""
    target = domain.target
    root = target.FindFirstGlobalVariable("mono_root_domain")
    name = string_member (domain, "friendly_name")
    if root.IsValid () and root.deref.addr.GetOffset () == root.deref.addr.GetOffset ():
        return "[root]"
    else:
        return "[{0}]".format (name)

def print_object(valobj, internal_dict):
    obj = valobj
    if isnull (obj):
        return ""
    domain = member (member (obj, "vtable"), "domain")
    klass = member (member (obj, "vtable"), "klass")
    return print_domain (domain, None) + print_class (klass, None)

# Register pretty printers
# FIXME: This cannot pick up the methods define in this module, leading to warnings
lldb.debugger.HandleCommand ("type summary add -w mono -F mono.print_method MonoMethod")
lldb.debugger.HandleCommand ("type summary add -w mono -F mono.print_class MonoClass")
lldb.debugger.HandleCommand ("type summary add -w mono -F mono.print_type MonoType")
lldb.debugger.HandleCommand ("type summary add -w mono -F mono.print_domain MonoDomain")
lldb.debugger.HandleCommand ("type summary add -w mono -F mono.print_object MonoObject")
lldb.debugger.HandleCommand ("type category enable mono")

# Helper commands for runtime debugging
# These resume the target
# Print the method at the current ip
lldb.debugger.HandleCommand ("command alias pip p mono_print_method_from_ip((void*)$pc)")
# Print the method at the provided ip
lldb.debugger.HandleCommand ("command regex pmip 's/^$/p mono_print_method_from_ip((void*)$pc)/' 's/(.+)/p mono_print_method_from_ip((void*)(%1))/'")

print "Mono support mode loaded."
