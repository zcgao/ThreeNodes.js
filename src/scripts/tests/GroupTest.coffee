define [
  'use!Underscore', 
  'use!Backbone',
  "order!libs/qunit-git",
], (_, Backbone) ->
  "use strict"
  
  $ = jQuery
  
  class GroupTest
    constructor: (app) ->
      module "Group test"
      filehandler = app.file_handler
      ng = app.nodegraph
      
      test "Basic group", () ->
        app.clearWorkspace()
        
        n1 = ng.create_node("Number")
        n2 = ng.create_node("Vector3")
        node_mult = ng.create_node("MathMult")
        
        n1.v_in.setValue 2
        node_mult.rack.getField("factor").setValue(3)
        
        c1 = ng.connections.create
          from_field: n1.v_out
          to_field: node_mult.v_in
        
        ng.render()
        
        selected_nodes = [n1, n2, node_mult]
        definition = app.group_definitions.groupSelectedNodes(selected_nodes)
        
        equals ng.length, 1, "There is one group node"
        grp = ng.models[0]
        equals grp.subgraph.length, 3, "The group node has 3 subnodes"
        console.log grp
        nbr_in1 = grp.rack.node_fields.inputs["in-1"]
        mult_out1 = grp.rack.node_fields.outputs["out-12"]
        mult_fact1 = grp.rack.node_fields.inputs["factor-12"]
        
        nbr_in1.setValue 5
        mult_fact1.setValue 3
        ng.render()
        # 5 * 3
        equals mult_out1.getValue(), 15, "Group 1 sends correct value (1/2)"
        nbr_in1.setValue 2
        ng.render()
        # 2 * 3
        equals mult_out1.getValue(), 6, "Group 1 sends correct value (2/2)"
        
        # Create a second group node based on the same definition
        model =
          type: "Group"
          definition: definition
        ng.createGroup(model)
        ng.render()
        
        equals ng.length, 2, "There is two group nodes"
        grp2 = ng.models[1]
        equals grp2.subgraph.length, 3, "The group2 has 3 subnodes"
        console.log grp2
        nbr_in2 = grp2.rack.node_fields.inputs["in-1"]
        mult_out2 = grp2.rack.node_fields.outputs["out-12"]
        mult_fact2 = grp2.rack.node_fields.inputs["factor-12"]
        
        # Set different values for the second group but don't touch the first one
        
        nbr_in2.setValue 11
        mult_fact2.setValue 2
        ng.render()
        # 11 * 2
        equals mult_out1.getValue(), 6, "Group 1 value has not changed (1/2)"
        equals mult_out2.getValue(), 22, "Group 2 sends correct value (1/2)"
        
        nbr_in2.setValue 2
        ng.render()
        # 2 * 2
        equals mult_out1.getValue(), 6, "Group 1 value has not changed (2/2)"
        equals mult_out2.getValue(), 4, "Group 2 sends correct value (1/2)"
        
        # Save current group in json for next test
        @saved_grp = filehandler.get_local_json()
        
        app.clearWorkspace()
        console.log "######"
        console.log @saved_grp
        equals ng.length, 0, "The workspace is empty"
        
        # Load the previous workspace which had 2 groups
        filehandler.load_from_json_data(@saved_grp)
        ng.render()
        equals ng.length, 2, "The two group nodes have been loaded"
        grp = ng.models[0]
        equals grp.subgraph.length, 3, "The group node has 3 subnodes"
        