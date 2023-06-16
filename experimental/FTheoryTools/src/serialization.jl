@registerSerializationType(ToricCoveredScheme{QQField})

function save_internal(s::SerializerState, tcs::ToricCoveredScheme{QQField})
  return Dict(
    :ntv => save_type_dispatch(s, tcs.ntv)
             )
end

function load_internal(s::DeserializerState, ::Type{ToricCoveredScheme{QQField}}, dict::Dict)
  return ToricCoveredScheme{QQField}(load_type_dispatch(s, NormalToricVariety, dict[:ntv]))
end

@registerSerializationType(GlobalTateModel)

function save_internal(s::SerializerState, gtm::GlobalTateModel)
  return Dict(
              :tate_as => save_type_dispatch(s, [gtm.tate_a1, gtm.tate_a2, gtm.tate_a3, gtm.tate_a4, gtm.tate_a6]),
              :tate_polynomial => save_type_dispatch(s, gtm.tate_polynomial),
              :base_space => save_type_dispatch(s, gtm.base_space)
             )
end
